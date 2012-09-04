/*Copyright (c) 2012 Normal Software.  All rights reserved.The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license*/package com.davita.documents{	import flash.display.*;	import flash.ui.*;	import flash.events.*;	import flash.text.*;	import flash.net.*;	import flash.filters.*;	import flash.media.*;	import flash.external.*;	import flash.utils.*;	import fl.transitions.*;	import fl.transitions.easing.*;	import fl.events.*;	import com.davita.popups.*;	import com.davita.buttons.*;    import com.davita.events.*;    import com.davita.documents.*;	import com.davita.utilities.*;	import com.yahoo.astra.fl.managers.AlertManager;	import com.greensock.*;	import com.greensock.loading.*;	import com.greensock.events.LoaderEvent;	import com.greensock.loading.display.*;	/**	 *  base class for the davita course wrapper.	 *	The main application class for all DaVita courses.	 *  It is set as the base class of course.swf and contains the TableOfContents,	 *  course navigation buttons, Help, Search, and ClosedCaption.	 *	 *	 * 	@langversion ActionScript 3	 *	@playerversion Flash 9.0.0	 *	 *	@author Ian Kennedy	 *	@since  13.11.2007	 * 	@version 1.0	 */	public class CourseWrapperRW extends MovieClip	{		/* ============= */		/* = Variables = */		/* ============= */		public var versionNumber:String = "1.0";		public var currentPage:int;		private static var _finalPage:int;		private static var _bookmarkedPage:int = 0;		private var myContextMenu:ContextMenu = new ContextMenu();		//gating		private var _gated:Boolean = new Boolean();		private var _highestPageNumViewed:int = 0;		// LMS variables		private static var LMSStatus:String;		private static var LMSStudentName:String;		// xml variables		public var xmlLoader:URLLoader = new URLLoader();		public var courseXml:XML;		public var xmlSections:XMLList;		public var xmlPages:XMLList;		// text variables		private var courseTitle:String;		private var pageTitle:String;		private var copyright:String;		// popups		public var popupVisible:Boolean = new Boolean();		private var courseNavButtonSet:ButtonSet = new ButtonSet();		// review section variables		public var _reviewInfo:Array = new Array();		public var almostCorrectReviewPages:Array = new Array();		public var incorrectReviewPages:Array = new Array();		// SCORM		public var scorm:SCORM = new SCORM();		private var success:Boolean = false;		private var completion_status:String;		// loader variables		private var preloaderProgress_txt:TextField = new TextField();		private var loadedPage:MovieClip;		private var queue:SWFLoader = new SWFLoader({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});		// testing		public var course:Object = {			lesson_status: "",			student_name: "",			student_id: ""		}		private var _miles:int;		private var _challenges:int;		private var _bookmark:int;		private var _bookmarkMilesChallengesArray:Array;		/* =============== */		/* = Constructor = */		/* =============== */		/**		 *	@constructor		 */		public function CourseWrapperRW()		{			addEventListener(Event.ADDED_TO_STAGE, init);		}		/* ======================= */		/* = Initialize function = */		/* ======================= */		private function init(event:Event):void		{			success = scorm.connect();			console("scorm.connect(): " + success);			if(success){				//Set course variables				course.lesson_status = scorm.get("cmi.completion_status");				//If course has already been completed				if(course.lesson_status == "passed" || course.lesson_status == "completed"){					console("You have already completed this course.");					//Disconnect from the LMS.					scorm.disconnect();				} else {					//Set course status to incomplete					success = scorm.set("cmi.completion_status", "incomplete");					console("scorm.set('cmi.completion_status', 'incomplete'): " +success);					_bookmarkedPage = getBookmark();					if(success){						scorm.save();					} else {						serverUnresponsive();					}					// --- Get SCORM data as needed -----					course.student_id = scorm.get("cmi.learner_id");					console("scorm.get('cmi.learner_id'): " +course.student_id);					course.student_name = scorm.get("cmi.learner_name");					console("scorm.get('cmi.learner_name'): " +course.student_name);				}			} else {				serverUnresponsive();			}			// load course.xml			xmlLoader.load(new URLRequest("course.xml"));			xmlLoader.addEventListener(Event.COMPLETE, xmlLoaded);			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlLoaderErrorHandler);			// add buttons to the courseNavButtonSet ButtonSet and place them on the stage			courseNavButtonSet.addButtons([prev_btn, reload_btn, next_btn]);			addChild(courseNavButtonSet);			// event handlers for navigation buttons			prev_btn.addEventListener(MouseEvent.CLICK, previousPage);			next_btn.addEventListener(MouseEvent.CLICK, nextPage);			reload_btn.addEventListener(MouseEvent.CLICK, reloadPage);			close_btn.addEventListener(MouseEvent.CLICK, closeCourse);			// top level event handlers			addEventListener(CourseEvent.PAGE_CHANGED, updateCourseStatus);            // contextMenu            removeDefaultMenuItems();            addMenuItems();            this.contextMenu = myContextMenu;            // game listeners            addEventListener(ScoreSetEvent.SCORE_SET, LMSSetSuspendData);            addEventListener(ScorePollEvent.SCORE_POLLED, scorePolled);		}		/* ================ */		/* = game testing = */		/* ================ */		public function LMSSetSuspendData(event:ScoreSetEvent):void		{			// this will get event.mielsAndChallengesArray			trace("CourseWrapperRW::LMSSetSuspendData(" + event.toString() + ")");			var theSuspendDataArray:Array = event.bookmarkMilesChallengesArray;			var suspendDataString:String = theSuspendDataArray.toString();			scorm.set("cmi.suspend_data", suspendDataString);			this._bookmark = event.bookmarkMilesChallengesArray[0];			this._miles = event.bookmarkMilesChallengesArray[1];			this._challenges = event.bookmarkMilesChallengesArray[2];			postScore(event);		}		private function scorePolled(event:Object):void		{			trace("CourseWrapperRW::scorePolled("+event.toString()+")");			this._bookmarkMilesChallengesArray = [this._bookmark, this._miles, this._challenges];			dispatchEvent(new ScoreSetEvent(ScoreSetEvent.SCORE_SET, this._bookmarkMilesChallengesArray));		}		private function postScore(event:Object):void		{			trace("CourseWrapperRW::postScore(" + event.toString() + ")");			this._bookmarkMilesChallengesArray = [this._bookmark, this._miles, this._challenges];			dispatchEvent(new ScoreUpdatedEvent(ScoreUpdatedEvent.SCORE_UPDATED, this._bookmarkMilesChallengesArray));		}		private function console(msg):void {			trace("CourseWrapperRW::console(): " + msg);		}		public function LMSGetSuspendData():String		{			var theSuspendData:String = scorm.get("cmi.suspend_data");			trace("CourseWrapperRW::LMSGetSuspendData:: " + theSuspendData);			var theSuspendDataArray:Array = theSuspendData.split(",");			trace("CourseWrapperRW::LMSGetSuspendDataArrat:: " + theSuspendDataArray);			this._bookmark = theSuspendDataArray[0];			this._miles = theSuspendDataArray[1];			this._challenges = theSuspendDataArray[2];			return theSuspendData;		}		public function getBookmark():Number		{			LMSGetSuspendData();			trace("CourseWrapperRW::getBookmark() = " + _bookmarkedPage);			if (_bookmarkedPage.toString() != null)			{				return _bookmarkedPage;			}			else			{				return 0;			}		}		public function getMiles():Number		{			LMSGetSuspendData();			trace("CourseWrapperRW::getMiles() = " + this._miles);			if (this._miles.toString() != null)			{				return this._miles;			}			else			{				return 0;			}		}		public function getChallenges():Number		{			LMSGetSuspendData();			trace("CourseWrapperRW::getChallenges() = " + this._challenges);			if (this._challenges.toString() != null)			{				return this._challenges;			}			else			{				return 0;			}		}		/* ====================== */		/* = debugger functions = */		/* ====================== */		public function startDebugger(event:ContextMenuEvent):void		{            var filename:String = xmlPages[currentPage].@source.split("/")[1];            var myLoadedSWF = queue.rawContent as MovieClip;			var debugAlertText = "This is the file named: " + filename + " at frame: " + myLoadedSWF.currentFrame;			trace("This is the file named: " + filename + " at frame: " + myLoadedSWF.currentFrame);			AlertManager.createAlert(this, debugAlertText);		}		/* ========================= */		/* = contextMenu functions = */		/* ========================= */		private function removeDefaultMenuItems():void		{			myContextMenu.hideBuiltInItems();			var defaultItems:ContextMenuBuiltInItems = myContextMenu.builtInItems;		}		private function addMenuItems():void		{			var showReviewItem:ContextMenuItem = new ContextMenuItem("Show Review Info");			myContextMenu.customItems.push(showReviewItem);			showReviewItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, startDebugger);		}		/* ============================ */		/* = preloader event handlers = */		/* ============================ */		//		// queue event handlers		//		/**		 *	loads the requested page and dispatches a PAGE_CHANGED event		 */        public function unloadAndDestroy():void        {			var myLoadedSWF = queue.rawContent as MovieClip;			SoundMixer.stopAll();            queue.unload();            queue.dispose();            queue = null;        }		public function loadPage(page:int):void		{			unloadAndDestroy();			queue = new SWFLoader(xmlPages[page].@source, {name:'myLoader',container:this, y:59, estimatedBytes:460800,onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});			setCurrentPage(page);			queue.load(true);			dispatchEvent(new CourseEvent(CourseEvent.PAGE_CHANGED, page));		}		/* ======================= */		/* = LoaderMax functions = */		/* ======================= */		private function progressHandler(event:LoaderEvent):void {            var progressPercent = Math.round(event.target.progress * 100);			preloaderProgress_txt.width = 80;			preloaderProgress_txt.height = 40;			preloaderProgress_txt.background = true;			preloaderProgress_txt.backgroundColor = 0x305587;			preloaderProgress_txt.textColor = 0xFFFFFF;			this.addChild(preloaderProgress_txt);			preloaderProgress_txt.x = 460;			preloaderProgress_txt.y = 280;			preloaderProgress_txt.text = "\n   " + progressPercent + "% loaded   ";		}		private function completeHandler(event:LoaderEvent):void {			this.removeChild(preloaderProgress_txt);			trace(event.target + " is complete!");		}		private function errorHandler(event:LoaderEvent):void {			trace("error occured with " + event.target + ": " + event.text);		}		/**		 *	triggered once the xml has loaded		 */		private function xmlLoaded(event:Event):void		{			// convenience variables			courseXml = XML(event.target.data);			xmlSections = courseXml.children();			xmlPages = courseXml.children().children();			setFinalPage(xmlPages.length()-1);			// set the course title & description			setCourseTitle(courseXml.@title);			setCopyright(courseXml.@copyright);			setTitleText();			// load the the bookmarked page, if it exists			if (_bookmarkedPage != 0)			{				loadPage(_bookmarkedPage);			}			// otherwise, load the first page, or the page deep linked using #pagenum			else			{					loadPage(0);			}		}		private function xmlLoaderErrorHandler(event:IOErrorEvent):void		{			AlertManager.createAlert(this, "There has been a problem loading the course. Please close the course and email askisolutions@davita.com. Please include the name of this course in your email. Thank you.");			ExternalInterface.call( "console.error" , "Problem loading xml");		}		/**		 *	triggered by loadPage().		 *	checks for first or last page,		 *	sets the course and page title and		 *	bookmarks the current page.		 */		function updateCourseStatus(event:CourseEvent):void		{			// send a bookmark call to the LMS			scorm.set("cmi.suspend_data", currentPage + "," + _miles + "," + _challenges);			// set the page title			setPageTitle(xmlPages[currentPage].@title);			setTitleText();			// check for first and last page			switch (currentPage){				case 0 :					prev_btn.disableButton();					prev_btn.removeEventListener(MouseEvent.CLICK, previousPage);				break;				case _finalPage :					next_btn.disableButton();					next_btn.removeEventListener(MouseEvent.CLICK, nextPage);				break;				default:					if (!prev_btn.isEnabled)					{						prev_btn.enableButton();						prev_btn.addEventListener(MouseEvent.CLICK, previousPage);					}					if(!next_btn.isEnabled)					{						next_btn.enableButton();						next_btn.addEventListener(MouseEvent.CLICK, nextPage);					}			}			// run setHighestPageNumViewed			if (this._gated)			{				setHighestPageNumViewed(currentPage);			}		}		/* =========================== */		/* = course gating functions = */		/* =========================== */		public function setCourseAsGated():void		{			if (!this._gated)			{				this._gated = true;				closeGate();			}		}		public function closeGate():void		{			disableNextAndContentsButtons();		}		public function openGate():void		{			enableNextAndContentsButtons();		}		private function disableNextAndContentsButtons():void		{			next_btn.disableButton();			contents_btn.disableButton();			next_btn.removeEventListener(MouseEvent.CLICK, nextPage);			contents_btn.removeEventListener(MouseEvent.CLICK, togglePage);		}		private function enableNextAndContentsButtons():void		{			next_btn.enableButton();			//contents_btn.enableButton();			next_btn.addEventListener(MouseEvent.CLICK, nextPage);			//contents_btn.addEventListener(MouseEvent.CLICK, togglePage);		}		private function setHighestPageNumViewed(pageNum:int):void		{			if (currentPage >= this._highestPageNumViewed)			{				this._highestPageNumViewed = currentPage;				closeGate();			}			else			{				if (currentPage != _finalPage)				{					openGate();				}			}		}		/* =========== */		/* = Buttons = */		/* =========== */		//		// navigation buttons		//		/**		 *	loads the next page		 *	advances the course		 */		public function nextPage(event:MouseEvent):void		{			setCurrentPage(currentPage+1);			loadPage(currentPage);		}		/**		 *	loads the previous page		 *	moves backwards through the course		 */		public function previousPage(event:MouseEvent):void		{			setCurrentPage(currentPage-1);			loadPage(currentPage);		}		/**		 *	reloads the current page		 */		public function reloadPage(event:MouseEvent):void		{			loadPage(currentPage);		}		/**		 *	sends a call to the course.js closeCourse() method.		 */		private function closeCourse(event:MouseEvent):void		{			trace("CourseWrapperRW::closeCourse()");			ExternalInterface.call("closeCourse");		}		//		// section buttons		//		//		// button and buttonSet helpers		//		/**		 *	disables all of the main courseNavButtons except for the active section.		 */		private function disableButtonsExcept(buttonName:String):void		{			// remove the CLICK listener from the navigation buttons			next_btn.removeEventListener(MouseEvent.CLICK, nextPage);			prev_btn.removeEventListener(MouseEvent.CLICK, previousPage);			reload_btn.removeEventListener(MouseEvent.CLICK, reloadPage);			// loop through the courseNavButtonSet			for each (var b:MovieClip in courseNavButtonSet.buttons){				if (b.name != buttonName)				{					// disable the buttons using the CourseNavButton class					b.disableButton();					// disable the buttons in the popupButtonSet					for each (var c:MovieClip in popupButtonSet.buttons)					{						if (c.name != buttonName)						{							b.removeEventListener(MouseEvent.CLICK, togglePage);						}					}				}			}		}		/**		 *	enables all courseNavButtons		 */		private function enableAllButtons():void		{			// add the CLICK listener to the navigation butons			next_btn.addEventListener(MouseEvent.CLICK, nextPage);			prev_btn.addEventListener(MouseEvent.CLICK, previousPage);			reload_btn.addEventListener(MouseEvent.CLICK, reloadPage);			// loop through the courseNavButtonSet and enable the buttons			for each (var b:MovieClip in courseNavButtonSet.buttons)			{				b.enableButton();				for each (var c:MovieClip in popupButtonSet.buttons)				{					c.addEventListener(MouseEvent.CLICK, togglePage);				}			}		}		/* ================== */		/* = Getter/Setters = */		/* ================== */		public function getCurrentPage():int		{			return currentPage;		}		public function setCurrentPage( page:int ):void		{			if( page != currentPage )			{				currentPage = page;			}		}		public function setFinalPage(page:int):void		{			if (xmlPages)			{				_finalPage = page;			}		}		public function getBookmarkedPage():int		{			return _bookmarkedPage;		}		public function setBookmarkedPage( value:int ):void		{			if( value != _bookmarkedPage )			{				_bookmarkedPage = value;			}		}		public function getCourseTitle():String		{			return courseTitle;		}		/**		 *	sets the course title (should get it from xml)		 */		public function setCourseTitle( value:String ):void		{			if( value != courseTitle )			{				courseTitle = value;			}		}		public function getPageTitle():String		{			if (pageTitle)			{				return pageTitle;			} else {				return "";			}		}		/**		 *	sets the page title (should get it from the xml)		 */		public function setPageTitle( value:String ):void		{			if( value != pageTitle )			{				pageTitle = value;			}		}		public function getCopyright():String		{			if (copyright != "")			{				return copyright;			} else {				return "©2012 DaVita Inc.";			}		}		/**		 *	sets the copyright (should get it from the xml)		 */		public function setCopyright( value:String ):void		{			if( value != copyright )			{				copyright = value;			}		}		/**		 *	sets the course/page title in the wrapper header		 */		public function setTitleText():void		{			var c:String = getCourseTitle();			var p:String = getPageTitle();			var cr:String = getCopyright();			copyrightTextField.text = cr;			courseTitleTextField.text = c;			pageTitleTextField.text = p;			pageNumTextField.text = (currentPage + 1).toString() + " of " + (_finalPage + 1).toString();		}		/* ================= */		/* = LMS Functions = */		/* ================= */		/**		 *	sets the course status to complete on the LMS		 */		public function LMSSetComplete():void		{			success = scorm.set("cmi.completion_status", "completed");			if(success)			{				scorm.disconnect();			}			else			{				serverUnresponsive();			}		}		/**		 *	sends the score to the LMS and marks the course		 *	status as passed or failed		 */		public function LMSSetScore(score:Number, passingScore:Number):void		{				// success = scorm.set("cmi.core.score.raw", score.toString());				success = scorm.set("cmi.score.raw", score.toString());				if (success)				{					if (score < passingScore)					{						/*scorm.set("cmi.core.lesson_status", "failed");*/						scorm.set("cmi.success_status", "failed");						/*scorm.disconnect();*/					}					else					{						/*scorm.set("cmi.core.lesson_status", "passed");*/						scorm.set("cmi.success_status", "passed");						/*scorm.disconnect();			*/					}				}				else				{					serverUnresponsive();				}		}		private function serverUnresponsive():void {			ExternalInterface.call("alert", "We apologize for the problem you are experiencing trying to connect to the LMS. We suggest you try closing the course and re-launching it, if you continue to experience this problem please contact the IT HelpDesk at 888-782-8737.");		}	}}