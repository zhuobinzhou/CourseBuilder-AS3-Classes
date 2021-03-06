/*
Copyright (c) 2012 Normal Software.  All rights reserved.
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
 */
package com.davita.documents {
	import com.davita.buttons.*;
	import com.davita.events.*;
	import com.davita.utilities.SCORM;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.*;
	import com.yahoo.astra.fl.managers.AlertManager;
	import com.junkbyte.console.Cc;

	import flash.display.*;
	import flash.events.*;
	import flash.external.*;
	import flash.media.*;
	import flash.net.*;
	import flash.text.*;
	import flash.ui.*;

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
	 * 	@version 1.0
	 */
	public class CourseWrapperNocturnal extends MovieClip {
		/* ============= */
		/* = Variables = */
		/* ============= */
		public var versionNumber : String = "1.0";
		public var currentPage : int;
		private static var _finalPage : int;
		private var _bookmarkedPage : int;
		private var myContextMenu : ContextMenu = new ContextMenu();
		// LMS variables
		private static var LMSStatus : String;
		private static var LMSStudentName : String;
		// xml variables
		public var xmlLoader : URLLoader = new URLLoader();
		public var courseXml : XML;
		public var xmlSections : XMLList;
		public var xmlPages : XMLList;
		// text variables
		private var courseTitle : String;
		private var pageTitle : String;
		private var copyright : String;
		// popups
		public var popupVisible : Boolean = new Boolean();
		private var courseNavButtonSet : ButtonSet = new ButtonSet();
		// SCORM
		public var scorm : SCORM = new SCORM();
		private var success : Boolean = false;
		// loader variables
		private var preloaderProgress_txt : TextField = new TextField();
		public var loadedPage : MovieClip;
		private var queue : SWFLoader = new SWFLoader({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});
		// testing
		public var course : Object = {lesson_status:"", student_name:"", student_id:""};
		private var _points : int;
		public var _bookmarkPoints : Array;

		/* =============== */
		/* = Constructor = */
		/* =============== */
		/**
		 *	@constructor
		 */
		public function CourseWrapperNocturnal() {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		/* ======================= */
		/* = Initialize function = */
		/* ======================= */
		private function init(event : Event) : void {
			success = scorm.connect();
			Cc.config.commandLineAllowed = true;
			Cc.config.tracing = true;
			Cc.config.maxLines = 2000;
			Cc.start(this, "dbf");

			if (success) {
				// Set course variables
				course.lesson_status = scorm.get("cmi.core.lesson_status");
				// If course has already been completed
				if (course.lesson_status == "passed" || course.lesson_status == "completed") {
					var debugAlertText = "You have already completed this course.";
					AlertManager.createAlert(this, debugAlertText);

					// Disconnect from the LMS.
					scorm.disconnect();
				} else {
					// Set course status to incomplete
					success = scorm.set("cmi.core.lesson_status", "incomplete");

					if (success) {
						scorm.save();
					} else {
						serverUnresponsive();
					}
					// --- Get SCORM data as needed -----
				}
			} else {
				serverUnresponsive();
			}

			// load course.xml
			xmlLoader.load(new URLRequest("course.xml"));
			xmlLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlLoaderErrorHandler);

			// add buttons to the courseNavButtonSet ButtonSet and place them on the stage
			courseNavButtonSet.addButtons([prev_btn, reload_btn, next_btn]);
			addChild(courseNavButtonSet);

			// event handlers for navigation buttons
			next_btn.addEventListener(MouseEvent.CLICK, nextPage);
			reload_btn.addEventListener(MouseEvent.CLICK, reloadPage);
			close_btn.addEventListener(MouseEvent.CLICK, closeCourse);

			// top level event handlers
			addEventListener(CourseEvent.PAGE_CHANGED, updateCourseStatus);

			// contextMenu
			removeDefaultMenuItems();
			addMenuItems();
			this.contextMenu = myContextMenu;
		}

		/* ================ */
		/* = game testing = */
		/* ================ */
		public function LMSSetSuspendData() : void {
			this._bookmarkPoints = [this._bookmarkedPage, this._points];
			scorm.set("cmi.suspend_data", this._bookmarkPoints.toString());
			scorm.set("cmi.core.lesson_location", _bookmarkedPage.toString());
			scorm.save();
		}

		private function console(msg:String) : void {
			ExternalInterface.call("console.error", msg);
		}

		public function LMSGetSuspendData() : String {
			var theSuspendData : String = scorm.get("cmi.suspend_data");
			var theSuspendDataArray : Array = theSuspendData.split(",");
			_bookmarkedPage = int(scorm.get("cmi.core.lesson_location"));
			_points = int(theSuspendDataArray[1]);
			return theSuspendData;
		}

		public function getBookmark() : Number {
			LMSGetSuspendData();
			trace("CourseWrapperRW::getBookmark() = " + _bookmarkedPage);
			if (_bookmarkedPage != null && _bookmarkedPage.toString() != '') {
				return _bookmarkedPage;
			} else {
				return 0;
			}
		}

		/* ====================== */
		/* = debugger functions = */
		/* ====================== */
		public function startDebugger(event : ContextMenuEvent) : void {
			var filename : String = xmlPages[currentPage].@source.split("/")[1];
			var myLoadedSWF:MovieClip = queue.rawContent as MovieClip;
			var debugAlertText:String = "This is the file named: " + filename + " at frame: " + myLoadedSWF.currentFrame;
			AlertManager.createAlert(this, debugAlertText);
		}

		/* ========================= */
		/* = contextMenu functions = */
		/* ========================= */
		private function removeDefaultMenuItems() : void {
			myContextMenu.hideBuiltInItems();
		}

		private function addMenuItems() : void {
			var showReviewItem : ContextMenuItem = new ContextMenuItem("Show Review Info");
			myContextMenu.customItems.push(showReviewItem);
			showReviewItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, startDebugger);
		}

		/* ============================ */
		/* = loader event handlers = */
		/* ============================ */
		/**
		 *	loads the requested page and dispatches a PAGE_CHANGED event
		 */
		public function unloadAndDestroy() : void {
			SoundMixer.stopAll();
			queue.unload();
			queue.dispose();
			queue = null;
		}

		public function loadPage(page : int) : void {
			unloadAndDestroy();
			queue = new SWFLoader(xmlPages[page].@source, {name:'myLoader', container:this, y:59, estimatedBytes:11500, onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});
			setCurrentPage(page);
			queue.load(true);
			dispatchEvent(new CourseEvent(CourseEvent.PAGE_CHANGED, page));
		}

		/* ======================= */
		/* = LoaderMax functions = */
		/* ======================= */
		private function progressHandler(event : LoaderEvent) : void {
			var progressPercent:Number = Math.round(event.target.progress * 100);

			preloaderProgress_txt.width = 80;
			preloaderProgress_txt.height = 40;
			preloaderProgress_txt.background = true;
			preloaderProgress_txt.backgroundColor = 0x305587;
			preloaderProgress_txt.textColor = 0xFFFFFF;

			this.addChild(preloaderProgress_txt);
			preloaderProgress_txt.x = 460;
			preloaderProgress_txt.y = 280;

			preloaderProgress_txt.text = "\n   " + progressPercent + "% loaded   ";
		}

		private function completeHandler(event : LoaderEvent) : void {
			this.loadedPage = queue.rawContent as MovieClip;
			this.removeChild(preloaderProgress_txt);
			trace(event.target + " is complete!");
		}

		private function errorHandler(event : LoaderEvent) : void {
			trace("error occured with " + event.target + ": " + event.text);
		}

		/**
		 *	triggered once the xml has loaded
		 */
		private function xmlLoaded(event : Event) : void {
			// convenience variables
			courseXml = XML(event.target.data);
			xmlSections = courseXml.children();
			xmlPages = courseXml.children().children();
			setFinalPage(xmlPages.length() - 1);

			// set the course title & description
			setCourseTitle(courseXml.@title);
			setCopyright(courseXml.@copyright);
			setTitleText();

			LMSGetSuspendData();

			// load the the bookmarked page, if it exists
			if (_bookmarkedPage != 0) {
				loadPage(_bookmarkedPage);
			}
			// otherwise, load the first page
			else {
				loadPage(0);
			}
		}

		private function xmlLoaderErrorHandler(event : IOErrorEvent) : void {
			AlertManager.createAlert(this, "There has been a problem loading the course. Please close the course and email askisolutions@davita.com. Please include the name of this course in your email. Thank you.");
			ExternalInterface.call("console.error", "Problem loading xml");
		}

		/**
		 *	triggered by loadPage().
		 *	checks for first or last page,
		 *	sets the course and page title and
		 *	bookmarks the current page.
		 */
		private function updateCourseStatus(event : CourseEvent) : void {
			// send a bookmark call to the LMS
			_bookmarkedPage = currentPage;
			LMSSetSuspendData();
			setPageTitle(xmlPages[currentPage].@title);
			setTitleText();

			// check for first and last page
			switch (currentPage) {
				case 0 :
					prev_btn.disableButton();
					prev_btn.removeEventListener(MouseEvent.CLICK, previousPage);
					break;
				case _finalPage :
					next_btn.disableButton();
					next_btn.removeEventListener(MouseEvent.CLICK, nextPage);
					break;
				default:
					if (!prev_btn.isEnabled) {
						prev_btn.enableButton();
						prev_btn.addEventListener(MouseEvent.CLICK, previousPage);
					}
					if (!next_btn.isEnabled) {
						next_btn.enableButton();
						next_btn.addEventListener(MouseEvent.CLICK, nextPage);
					}
			}
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
		public function nextPage(event : MouseEvent) : void {
			setCurrentPage(currentPage + 1);
			loadPage(currentPage);
		}

		/**
		 *	loads the previous page
		 *	moves backwards through the course
		 */
		public function previousPage(event : MouseEvent) : void {
			setCurrentPage(currentPage - 1);
			loadPage(currentPage);
		}

		/**
		 *	reloads the current page
		 */
		public function reloadPage(event : MouseEvent) : void {
			SoundMixer.stopAll();
			LMSGetSuspendData();
			Object(this.loadedPage).points = _points;
			Object(this.loadedPage).updateTextFields();
			this.loadedPage.gotoAndPlay(1);
		}

		/**
		 *	sends a call to the course.js closeCourse() method.
		 */
		private function closeCourse(event : MouseEvent) : void {
			ExternalInterface.call("closeCourse");
		}

		public function disableNextButton() : void {
			next_btn.disableButton();
			next_btn.removeEventListener(MouseEvent.CLICK, nextPage);
		}

		public function enableNextButton() : void {
			next_btn.enableButton();
			next_btn.addEventListener(MouseEvent.CLICK, nextPage);
		}

		/* ================== */
		/* = Getter/Setters = */
		/* ================== */
		public function get points() : int {
			return _points;
		}

		public function set points(thePoints : int) : void {
			_points = thePoints;
		}

		public function getCurrentPage() : int {
			return currentPage;
		}

		public function setCurrentPage(page : int) : void {
			if ( page != currentPage ) {
				currentPage = page;
			}
		}

		public function setFinalPage(page : int) : void {
			if (xmlPages) {
				_finalPage = page;
			}
		}

		public function getBookmarkedPage() : int {
			return _bookmarkedPage;
		}

		public function setBookmarkedPage(value : int) : void {
			if ( value != _bookmarkedPage ) {
				_bookmarkedPage = value;
			}
		}

		public function getCourseTitle() : String {
			return courseTitle;
		}

		/**
		 *	sets the course title (should get it from xml)
		 */
		public function setCourseTitle(value : String) : void {
			if ( value != courseTitle ) {
				courseTitle = value;
			}
		}

		public function getPageTitle() : String {
			if (pageTitle) {
				return pageTitle;
			} else {
				return "";
			}
		}

		/**
		 *	sets the page title (should get it from the xml)
		 */
		public function setPageTitle(value : String) : void {
			if ( value != pageTitle ) {
				pageTitle = value;
			}
		}

		public function getCopyright() : String {
			if (copyright != "") {
				return copyright;
			} else {
				return "©2012 DaVita Inc.";
			}
		}

		/**
		 *	sets the copyright (should get it from the xml)
		 */
		public function setCopyright(value : String) : void {
			if ( value != copyright ) {
				copyright = value;
			}
		}

		/**
		 *	sets the course/page title in the wrapper header
		 */
		public function setTitleText() : void {
			var c : String = getCourseTitle();
			var p : String = getPageTitle();
			var cr : String = getCopyright();
			copyrightTextField.text = cr;
			courseTitleTextField.text = c;
			pageTitleTextField.text = p;
			pageNumTextField.text = (currentPage + 1).toString() + " of " + (_finalPage + 1).toString();
		}

		/* ================= */
		/* = LMS Functions = */
		/* ================= */
		/**
		 *	sets the course status to complete on the LMS
		 */
		public function LMSSetComplete() : void {
			success = scorm.set("cmi.core.lesson_status", "completed");
			if (success) {
				scorm.save();
				scorm.disconnect();
			} else {
				serverUnresponsive();
			}
		}

		/**
		 *	sends the score to the LMS and marks the course
		 *	status as passed or failed
		 */
		public function LMSSetScore(score : Number, passingScore : Number) : void {
			// success = scorm.set("cmi.core.score.raw", score.toString());
			success = scorm.set("cmi.score.raw", score.toString());
			if (success) {
				if (score < passingScore) {
					scorm.set("cmi.core.lesson_status", "failed");
					// scorm.set("cmi.success_status", "failed");
					/*scorm.disconnect();*/
				} else {
					scorm.set("cmi.core.lesson_status", "passed");
					// scorm.set("cmi.success_status", "passed");
					/*scorm.disconnect();			*/
				}
			} else {
				serverUnresponsive();
			}
		}

		private function serverUnresponsive() : void {
			ExternalInterface.call("alert", "We apologize for the problem you are experiencing trying to connect to the LMS. We suggest you try closing the course and re-launching it, if you continue to experience this problem please contact the IT HelpDesk at 888-782-8737.");
		}
	}
}
