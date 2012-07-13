﻿/*
Copyright (c) 2009 Normal Software.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.davita.documents
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.net.*;
	import flash.filters.*;
	import flash.media.*;
	import flash.external.*;
	import flash.utils.*;
	
	import fl.transitions.*;
	import fl.transitions.easing.*;
	import fl.events.*;

	import com.davita.popups.*;
	import com.davita.buttons.*;
    import com.davita.events.*;
    import com.davita.documents.*;
	import com.davita.utilities.*;
	
	import com.yahoo.astra.fl.managers.AlertManager;
	import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.display.*;	

	/**
	 *  base class for the davita course wrapper.
	 *	The main application class for all DaVita courses.
	 *  It is set as the base class of course.swf and contains the TableOfContents,
	 *  course navigation buttons, Help, Search, and ClosedCaption.
	 *	
	 *	
	 * 	@langversion ActionScript 3
	 *	@playerversion Flash 9.0.0
	 *
	 *	@author Ian Kennedy
	 *	@since  13.11.2007
	 */
	public class PreviewWrapper extends MovieClip
	{
		/* ============= */
		/* = Variables = */
		/* ============= */
		public var currentPage:int;
		private static var _finalPage:int;
		private static var _bookmarkedPage:int = 0;

		//gating
		private var _gated:Boolean = new Boolean();
		private var _highestPageNumViewed:int = 0;
		
		// LMS variables
		private static var LMSStatus:String;
		private static var LMSStudentName:String;		

		// xml variables 
		public var xmlLoader:URLLoader = new URLLoader();
		public var courseXml:XML;
		public var xmlSections:XMLList;
		public var xmlPages:XMLList;
		
		// text variables
		private var courseTitle:String;
		private var pageTitle:String;

		// custom class variables
		public var popupVisible:Boolean = new Boolean();
		
		private var courseNavButtonSet:ButtonSet = new ButtonSet();
		private var popupButtonSet:ButtonSet = new ButtonSet();

		private var tableOfContents = new TableOfContents();
		private var help:Help = new Help();
		private var search:Search = new Search();
		public var closedCaption:ClosedCaption = new ClosedCaption();
		
		// review section variables
		public var _reviewInfo:Array = new Array();
		public var almostCorrectReviewPages:Array = new Array();
		public var incorrectReviewPages:Array = new Array();

		// MaxLoader Testing
		private var queue:LoaderMax = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});
		
		/* =============== */
		/* = Constructor = */
		/* =============== */
		
		/**
		 *	@constructor
		 */
		public function PreviewWrapper()
		{	
			addEventListener(Event.ADDED_TO_STAGE, init);			
		}

		/* ======================= */
		/* = Initialize function = */
		/* ======================= */
		private function init(event:Event):void
		{	
					
			// load course.xml
			xmlLoader.load(new URLRequest("course.xml"));
			xmlLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlLoaderErrorHandler);

			// add buttons to the courseNavButtonSet ButtonSet and place them on the stage
			courseNavButtonSet.addButtons([contents_btn, prev_btn, reload_btn, next_btn, help_btn, search_btn, closedCaption_btn]);
			addChild(courseNavButtonSet);

			popupButtonSet.addButtons([contents_btn, help_btn, search_btn]);
			addChild(popupButtonSet);

			// event handlers for popups buttons
			contents_btn.addEventListener(MouseEvent.CLICK, togglePage);
			help_btn.addEventListener(MouseEvent.CLICK, togglePage);
			search_btn.addEventListener(MouseEvent.CLICK, togglePage);
			closedCaption_btn.addEventListener(MouseEvent.CLICK, toggleCC);

			// these work because we've named the close button "popupName"_btn
			tableOfContents.contents_btn.addEventListener(MouseEvent.CLICK, togglePage);
			search.search_btn.addEventListener(MouseEvent.CLICK, togglePage);
			help.help_btn.addEventListener(MouseEvent.CLICK, togglePage);

			// event handlers for navigation buttons
			prev_btn.addEventListener(MouseEvent.CLICK, previousPage);
			next_btn.addEventListener(MouseEvent.CLICK, nextPage);
			reload_btn.addEventListener(MouseEvent.CLICK, reloadPage);
			close_btn.addEventListener(MouseEvent.CLICK, closeCourse);

			// event handlers for the popups
			tableOfContents.tocTree.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, tocLoadPage);

			// hide the closed caption button for now
			closedCaption_btn.visible = false;

			// top level event handlers
			addEventListener(CourseEvent.PAGE_CHANGED, updateCourseStatus);
			addEventListener(CaptionEvent.CAPTION_CHANGED, closedCaption.updateCaption);
			addEventListener(ReviewEvent.REVIEW_CHANGED, updateReviewInfo);
		}
		// LoaderMax Functions

		function progressHandler(event:LoaderEvent):void {
		    progressBar_mc.scaleX = event.target.progress;
		}
		
		private function completeHandler(event:LoaderEvent):void {
		  trace(event.target + " is complete!");
		}
		 
		private function errorHandler(event:LoaderEvent):void {
			trace("error occured with " + event.target + ": " + event.text);
		}
		
		// End LoaderMax Functions

		/**
		 *	triggered once the xml has loaded
		 */
		private function xmlLoaded(event:Event):void
		{
			
			// convenience variables
			courseXml = XML(event.target.data);
			xmlSections = courseXml.children();
			xmlPages = courseXml.children().children();
			setFinalPage(xmlPages.length()-1);
			
			// send the xml to the tableOfContents and search
			tableOfContents.setXml(courseXml);
			search.setXml(courseXml);
						
			// set the course title & description
			setCourseTitle(courseXml.@title);
			setTitleText();
			
			// load the first swf or the bookmarked page, if it exists
			if (_bookmarkedPage != 0)
			{
				loadPage(_bookmarkedPage);
			}
			else
			{
				loadPage(0);
			}
		}
		
		public function replaceXml(newXml:XML):void 
		{
			xmlSections = newXml.children();
			xmlPages = newXml.children().children();
			setFinalPage(xmlPages.length()-1);

			// send the xml to the tableOfContents and search
			tableOfContents.setXml(newXml);
			search.setXml(newXml);
		}
				
		private function xmlLoaderErrorHandler(event:IOErrorEvent):void
		{
			AlertManager.createAlert(this, "Hm. There doesn't seem to be a course.xml around. If you find one, put it beside me. Until then, I'm useless.\r - Love, CoursePreview");
			trace("problem loading xml");
		}

		/**
		 *	triggered by loadPage().
		 *	checks for first or last page,
		 *	sets the course and page title and
		 *	bookmarks the current page.
		 */
		function updateCourseStatus(event:CourseEvent):void
		{						
			// set the page title
			setPageTitle(xmlPages[currentPage].@title);
			setTitleText();

			// if the closed caption is open, close it.
			// if closedCaption is visible, hide it
			if (closedCaption.isVisible)
			{
				closedCaption.hideCC();
			}

			// update the table of contents by passing along the event
			tableOfContents.updateToc(event);

			// check for first and last page
			switch (currentPage){
				case 0 :
					prev_btn.disableButton();
					prev_btn.removeEventListener(MouseEvent.CLICK, previousPage);
				break;
				case _finalPage :
					next_btn.disableButton();
					next_btn.removeEventListener(MouseEvent.CLICK, nextPage);
				break;
				default:
					if (!prev_btn.isEnabled)
					{
						prev_btn.enableButton();
						prev_btn.addEventListener(MouseEvent.CLICK, previousPage);
					}
					if(!next_btn.isEnabled)
					{
						next_btn.enableButton();
						next_btn.addEventListener(MouseEvent.CLICK, nextPage);
					}
			}

			// run setHighestPageNumViewed
			if (this._gated)
			{
				setHighestPageNumViewed(currentPage);
			}

		}


		
		/* =========================== */
		/* = course gating functions = */
		/* =========================== */
		
		public function setCourseAsGated():void
		{
			if (!this._gated)
			{
				trace("setting course as gated");
				this._gated = true;
				closeGate();				
			}
		}
		
		public function closeGate():void
		{
			trace("closing gate");
			disableNextAndContentsButtons();
		}
		
		public function openGate():void
		{
			trace("opening gate");
			enableNextAndContentsButtons();
		}
		
		private function disableNextAndContentsButtons():void
		{
			next_btn.disableButton();
			contents_btn.disableButton();
			next_btn.removeEventListener(MouseEvent.CLICK, nextPage);
			contents_btn.removeEventListener(MouseEvent.CLICK, togglePage);
		}
		
		private function enableNextAndContentsButtons():void
		{
			next_btn.enableButton();
			//contents_btn.enableButton();
			next_btn.addEventListener(MouseEvent.CLICK, nextPage);
			//contents_btn.addEventListener(MouseEvent.CLICK, togglePage);
		}
		
		private function setHighestPageNumViewed(pageNum:int):void
		{
			if (currentPage >= this._highestPageNumViewed)
			{
				this._highestPageNumViewed = currentPage;
				closeGate();
			}
			else 
			{
				if (currentPage != _finalPage)
				{
					openGate();
				}
			}
		}

		
	

		//
		// pageLoader event handlers
		//
		
		/**
		 *	loads the requested page and dispatches a PAGE_CHANGED event
		 */
		public function loadPage(page:int):void 
		{
			queue.empty(true, true);
			queue.append(new SWFLoader(xmlPages[page].@source, {name:'myLoader',container:this, y:60, estimatedBytes:460800}));
			setCurrentPage(page);
			queue.load(true);
			dispatchEvent(new CourseEvent(CourseEvent.PAGE_CHANGED, page));
		}						

		//
		// tableOfContents event handlers
		//
		
		/**
		 *	called on tableOfContents item DOUBLE_CLICK event
		 *	removes tableOfContents from stage, re-enables buttons
		 *	and loads the requested page.
		 */
		private function tocLoadPage(event:ListEvent):void
		{
			// check the event - sections don't have pagenums
			// but pages do...
			if (event.item.pagenum)
			{
				removeChild(tableOfContents);
				popupVisible = false;
				enableAllButtons(); 
				loadPage(event.item.pagenum-1);
			}
		}
		
		/**
		 *	called when student follows a link from the Search.
		 */
		public function searchLoadPage(page):void 
		{
			this.removeChild(search);
			this.popupVisible = false;
			this.enableAllButtons();
			this.loadPage(page-1);
		}
		
		/**
		 *	called on ReviewEvent:REVIEW_CHANGED
		 */
		private function updateReviewInfo(event:ReviewEvent):void
		{
			var tempReviewInfo:Array = event.reviewInfo;
			tempReviewInfo.unshift(currentPage);
						
			for (var i:int = 0; i<_reviewInfo.length; i++)
			{	
				// if we already have review info for this page
				// we'll delete the info at that index
				if (_reviewInfo[i][0] == currentPage)
				{
					_reviewInfo.splice(i,1);
				}
			}			
			
			_reviewInfo.push(tempReviewInfo);
			// TODO: figure out if i can store reviewInfo on the LMS
		}
										
		/* =========== */
		/* = Buttons = */
		/* =========== */

		//
		// navigation buttons
		//
		
		/**
		 *	loads the next page
		 *	advances the course
		 */
		public function nextPage(event:MouseEvent):void
		{
			setCurrentPage(currentPage+1);
			loadPage(currentPage);
		}

		/**
		 *	loads the previous page
		 *	moves backwards through the course
		 */
		public function previousPage(event:MouseEvent):void
		{
			setCurrentPage(currentPage-1);
			loadPage(currentPage);
		}

		/**
		 *	reloads the current page
		 */
		public function reloadPage(event:MouseEvent):void
		{
			loadPage(currentPage);
		}

		/**
		 *	sends a call to the course.js closeCourse() method.
		 */
		private function closeCourse(event:MouseEvent):void
		{
			/*if (ExternalInterface.available)
			{
				ExternalInterface.call("closeCourse");
			}*/
		}
		
		//
		// section buttons
		//
		
		/**
		 *	triggered when contents_btn, help_btn, or search_btn
		 *	are CLICKED. toggles their respective sections.
		 */
		private function togglePage(event:MouseEvent):void
		{
			if (! popupVisible){
				popupVisible = true;
				disableButtonsExcept(event.target.name);
				event.target.gotoAndStop(2);
								
				switch (event.target.name){
				case "contents_btn" :
					addChild(tableOfContents);
					tableOfContents.y = 60;
				break;
				case "help_btn" :
					addChild(help);
				break;
				case "search_btn" :
					addChild(search);
				break;
				}
			} else {
				popupVisible = false;
				enableAllButtons();
				event.target.gotoAndStop(1);
				
				switch (event.target.name){
				case "contents_btn" :
					removeChild(tableOfContents);
				break;
				case "help_btn" :
					removeChild(help);
				break;
				case "search_btn" :
					removeChild(search);
				break;
				}
			}	
		}
		
		/**
		 *	shows and hides the closed captions
		 */
		function toggleCC(event:MouseEvent):void
		{
			if (!closedCaption.isVisible){
				addChild(closedCaption);
				closedCaption.showCC();
			} else {
				closedCaption.hideCC();
			}
		}
		
		//
		// button and buttonSet helpers
		//
		
		/**
		 *	disables all of the main courseNavButtons except for the active section.
		 */
		private function disableButtonsExcept(buttonName:String):void
		{
			// remove the CLICK listener from the navigation buttons
			next_btn.removeEventListener(MouseEvent.CLICK, nextPage);
			prev_btn.removeEventListener(MouseEvent.CLICK, previousPage);
			reload_btn.removeEventListener(MouseEvent.CLICK, reloadPage);
			closedCaption_btn.removeEventListener(MouseEvent.CLICK, toggleCC);
			
			// loop through the courseNavButtonSet
			for each (var b:MovieClip in courseNavButtonSet.buttons){
				if (b.name != buttonName)
				{
					// disable the buttons using the CourseNavButton class
					b.disableButton();
					
					// disable the buttons in the popupButtonSet
					for each (var c:MovieClip in popupButtonSet.buttons)
					{
						if (c.name != buttonName)
						{
							b.removeEventListener(MouseEvent.CLICK, togglePage);
						}
					}
				}
			}
		}
		
		/**
		 *	enables all courseNavButtons
		 */
		private function enableAllButtons():void
		{
			// add the CLICK listener to the navigation butons
			next_btn.addEventListener(MouseEvent.CLICK, nextPage);
			prev_btn.addEventListener(MouseEvent.CLICK, previousPage);
			reload_btn.addEventListener(MouseEvent.CLICK, reloadPage);
			closedCaption_btn.addEventListener(MouseEvent.CLICK, toggleCC);
			
			// loop through the courseNavButtonSet and enable the buttons
			for each (var b:MovieClip in courseNavButtonSet.buttons)
			{
				b.enableButton();
				for each (var c:MovieClip in popupButtonSet.buttons)
				{
					c.addEventListener(MouseEvent.CLICK, togglePage);
				}
			}
			
		}
		
		/* ================== */
		/* = Getter/Setters = */
		/* ================== */
		
		public function getCurrentPage():int
		{ 
			return currentPage; 
		}

		public function setCurrentPage( page:int ):void 
		{
			if( page != currentPage )
			{
				currentPage = page;
			}
		}
		
		public function setFinalPage(page:int):void
		{
			if (xmlPages)
			{
				_finalPage = page;
			}
		}
		
		public function getBookmarkedPage():int 
		{ 
			return _bookmarkedPage; 
		}

		public function setBookmarkedPage( value:int ):void 
		{
			if( value != _bookmarkedPage )
			{
				_bookmarkedPage = value;
			}
		}
		
		public function getCourseTitle():String 
		{ 
			return courseTitle; 
		}

		/**
		 *	sets the course title (should get it from xml)
		 */
		public function setCourseTitle( value:String ):void 
		{
			if( value != courseTitle )
			{
				courseTitle = value;
			}
		}
		
		public function getPageTitle():String 
		{ 
			if (pageTitle)
			{
				return pageTitle;
			} else {
				return ""; 				
			}
		}

		/**
		 *	sets the page title (should get it from the xml)
		 */
		public function setPageTitle( value:String ):void 
		{
			if( value != pageTitle )
			{
				pageTitle = value;
			}
		}
		
		/**
		 *	sets the course/page title in the wrapper header
		 */
		public function setTitleText():void
		{
			var c:String = getCourseTitle();
			var p:String = getPageTitle();
			courseTitleTextField.text = c;
			pageTitleTextField.text = p;
			pageNumTextField.text = (currentPage + 1).toString() + " of " + (_finalPage + 1).toString();
		}
				
		/**
		 *	adds info from the self assessments and post tests
		 *	to be accessed by the review page.
		 */
		public function addReviewInfo(value:String):void 
		{
			_reviewInfo.push(value);
		}		
		
		/* ================= */
		/* = LMS Functions = */
		/* ================= */
				
		/**
		 *	get the students name from the LMS
		 */
		public function LMSGetStudentName():String
		{
			/*return scorm.get("cmi.core.student_name");*/
			return "hi";
		}
		
		/**
		 *	bookmarks a page on the LMS
		 */
		public function LMSSetBookmarkedPage(pageNumber):void
		{
			/*scorm.set("cmi.core.lesson_location", pageNumber);*/
		}

		/**
		 *	gets the bookmarked page from the LMS
		 */
		public function LMSGetBookmarkedPage():void
		{
			/*setBookmarkedPage(scorm.get("cmi.core.lesson_location") as int);*/
		}
		
		/**
		 *	sets the course status to complete on the LMS
		 */
		public function LMSSetComplete():void
		{
			/*scorm.set("cmi.core.lesson_status", "completed");*/
		}
		
		/**
		 *	sends the score to the LMS and marks the course
		 *	status as passed or failed
		 */
		public function LMSSetScore(score:Number, passingScore:Number):void
		{
			/*if (ExternalInterface.available)
						{
							success = scorm.set("cmi.core.score.raw", score);
							if (success)
							{
								if (score < passingScore)
								{
									scorm.set("cmi.core.lesson_status", "failed");
									scorm.disconnect();
								}
								else
								{
									scorm.set("cmi.core.lesson_status", "passed");
									scorm.disconnect();			
								}
							}
							else
							{
								serverUnresponsive();
							}
						}*/
		}
		
		function serverUnresponsive():void {
		    /*var msg:String = "Sorry, can't connect to server. Please try again later.";
		   		    trace(msg);
		   		    ExternalInterface.call("alert", msg);*/
		}
	}
}