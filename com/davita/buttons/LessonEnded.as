﻿/*
Copyright (c) 2009 Normal Software.  All rights reserved.
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.davita.buttons
{
	import flash.display.*;
	import flash.events.*;

	public class LessonEnded extends MovieClip
	{
		public var __courseSwf:Object;

		public function LessonEnded()
		{
			addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		function initialize(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);
			// find the courseSwf and add listeners
			var success:Boolean = findCourseSwf();
			if(success)
			{
				trace("LessonEnded::initialize(): courseSwf found");
				__courseSwf.stop();
			}
		}

		private function findCourseSwf():Boolean
		{
			var curParent:DisplayObjectContainer = this.parent;
			while (curParent)
			{
				trace("findCourseSwf::curParent = " + curParent);
				if (curParent.hasOwnProperty("sndChannel"))
				{
					__courseSwf = curParent;
					trace("LessonEnded:: found the courseSwf");
					return true;
				}
				curParent = curParent.parent;
			}
			trace("LessonEnded:: not in a courseSwf");
			return false;
		}

	}
}