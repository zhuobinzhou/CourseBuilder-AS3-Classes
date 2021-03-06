﻿/*
Copyright (c) 2012 Normal Software.  All rights reserved.
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.davita.nocturnal
{
	import flash.display.*;
	import flash.events.*;
	import fl.motion.easing.*;
	import flash.text.*;
	import flash.media.SoundChannel;
	import flash.media.Sound;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.media.SoundMixer;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import com.greensock.TimelineLite;
	import com.greensock.TweenLite;
	import fl.controls.RadioButtonGroup;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import com.davita.nocturnal.NocturnalAnimator;
	import com.davita.events.*;

	/**
	 *  base class for davita standard game files.
	 *
	 * @langversion ActionScript 3
	 * @playerversion Flash 9.0.0
	 *
	 * @author Dean Hawkey
	 * @since  2012
	 */

	public dynamic class CourseFileNocturnalGame extends MovieClip
	{
		// TODO: Move points into Nocturnal Wrapper
		public var points:int;

		// TODO: Most of these variables can be moved or deleted
		public var tf:TextFormat = new TextFormat("Arial",12,0xFFFFFF);
		public var avatarLoader:Loader = new Loader();
		public var restrictCorrect2one:Boolean = false;
		public var restrictScore2oneClick:Boolean = false;
		public var restrict2oneHintDeduction:Boolean = false;
		public var avatarLoading:MovieClip = new AvaLoader();
		private var closeSBTimer:Timer = new Timer(3000,1);
		private var nextFrameTimer:Timer = new Timer(3500,1);

		public var theAnimator = new NocturnalAnimator();
		private var _pageMask:Sprite = new Sprite();
		private var __courseWrapper:Object;

		public var scoreBoard_mc:MovieClip;
		public var correctButton_mc:MovieClip;
		public var incorrectButton_mc:MovieClip;
		private var avaPositionsX:int;
		private var avaPositionsY:int;

		// Audio

		var sndOpen:sbOpen = new sbOpen();
		var sndIdea:SFXidea = new SFXidea();
		var sndCorrect:SFXcorrect = new SFXcorrect();
		var sndWrong:SFXwrong = new SFXwrong();

		//---------------------------------------
		// CONSTRUCTOR
		//---------------------------------------
		public function CourseFileNocturnalGame():void
		{
			if (stage)
			{
				init();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}

		//---------------------------------------
		// PRIVATE METHODS
		//---------------------------------------
		private function init(e:Event = null):void
		{
			maskPage();

			var success:Boolean = findWrapper();
			if (success)
			{
				__courseWrapper.disableNextButton();
				points = __courseWrapper.points;
			}
		}

		private function findWrapper():Boolean
		{
			var curParent:DisplayObjectContainer = this.parent;
			while (curParent)
			{
				if (curParent.hasOwnProperty("versionNumber") && curParent.hasOwnProperty("currentPage"))
				{
					__courseWrapper = curParent;
					updateTextFields();
					trace("CourseFileNocturnalGame:: found the wrapper");
					return true;
				}
				curParent = curParent.parent;
			}
			trace("CourseFileNocturnalGame:: not in a wrapper");
			return false;
		}

		public function updateTextFields():void
		{
			scoreBoard_mc.txtPoints.text = points.toString();
		}

		private function helpSetup():void
		{
			// Help Icon
			help_mc.visible = false;
			help_mc.buttonMode = true;
			help_mc.useHandCursor = true;
			help_mc.addEventListener(MouseEvent.CLICK, helpClose);
			scoreBoard_mc.sbhelp_btn.addEventListener(MouseEvent.CLICK, helpOpen);
		}

		private function maskPage():void
		{
			_pageMask.graphics.beginFill(0x000000);
			_pageMask.graphics.drawRect(0,.5,1000,599.5);
			addChild(_pageMask);
			this.mask = _pageMask;
		}

		public function addPoints(addedPoints:int,playSound:String = "Open"):void
		{
			// increment points
			points = (points + addedPoints);
			if( __courseWrapper )
			{
				__courseWrapper.points = points;
			}

			// update scoreBoard
			scoreBoard_mc.open();
			updateTextFields();
			TweenLite.delayedCall(4,scoreBoard_mc.close);

			if (playSound == "right")
			{
				sndCorrect.play();
			}
			else if (playSound == "wrong")
			{
				sndWrong.play();
			}
			else
			{
				sndOpen.play();
			}
		}

		public function delayClose(e:TimerEvent)
		{
			scoreBoard_mc.close();
		}

		public function moveNext(e:TimerEvent)
		{
			nextFrame();
		}

		// SCORING   ------------------++++++++++++++++++
		private function correctClick(event:MouseEvent):void
		{
			trace("correctClick");
			var rightSound:Sound = new SFXcorrect();
			rightSound.play();
			this.theCensus_mc.gotoAndStop("Correct");
			nextFrameTimer.addEventListener(TimerEvent.TIMER, moveNext);
			nextFrameTimer.start();

			if (restrictCorrect2one == false)
			{
				this.scoreBoard_mc.txtPoints.textColor = 0x00FF66;
				restrictCorrect2one = true;
				addPoints(5);

				var closeSBTimer:Timer = new Timer(3000,1);
				closeSBTimer.addEventListener(TimerEvent.TIMER, delayClose);
				closeSBTimer.start();

				restrict2oneHintDeduction = true;
			}
			else
			{
				restrictScore2oneClick = true;
				trace("Already added to score, not doing it again.");
			}
		}

		private function correctInit():void
		{
			correctButton_mc.addEventListener(MouseEvent.CLICK, correctClick);
			correctButton_mc.buttonMode = true;
			correctButton_mc.useHandCursor = true;
			restrictScore2oneClick = false;
			restrictCorrect2one = false;
		}

		private function IncorrectInit():void
		{
			incorrectButton_mc.addEventListener(MouseEvent.CLICK, incorrectClick);
			incorrectButton_mc.buttonMode = true;
			incorrectButton_mc.useHandCursor = true;
		}

		private function incorrectClick(event:MouseEvent):void
		{
			var wrongSound:Sound = new SFXwrong();
			wrongSound.play();
			trace("Incorrect Click");

			if (restrictScore2oneClick == false)
			{
				this.scoreBoard_mc.txtPoints.textColor = 0xFF0000;
				restrictScore2oneClick = true;
				addPoints(-5);
				this.theCensus_mc.gotoAndStop("Incorrect");

				var closeSBTimer:Timer = new Timer(3000,1);
				closeSBTimer.addEventListener(TimerEvent.TIMER, delayClose);
				closeSBTimer.start();
			}
			else
			{
				this.theCensus_mc.gotoAndStop("Incorrect2");
				trace("Already deducted score, not doing it again.");
			}
		}

		// Make sure text changes
		public function changeText(evt:Event)
		{
			this.scoreBoard_mc.txtPoints.text = points.toString();
			stage.removeEventListener(Event.ENTER_FRAME, changeText);
		}

		// HELP FUNCTIONS
		private function helpClose(event:MouseEvent):void
		{
			this.help_mc.visible = false;
		}

		public function helpOpen(event:MouseEvent):void
		{
			this.help_mc.visible = true;
			var timeline:TimelineLite = new TimelineLite();
			timeline.append(TweenLite.from(this.help_mc, 1, {alpha:0}));
			timeline.append(TweenLite.to(this.help_mc, 1, {alpha:1}));
		}


		// [*********************** Avatar/Census Functions **********************]
		// AvatarPositions

		public function LoadAvaInPos(xPos,yPos,avatarLoader):void
		{
			// Align
			addChild(avatarLoader);
			avatarLoader.x = xPos;
			avatarLoader.y = yPos;
			avatarLoader.name = "Avatar";
			//avatarLoader.content.msPlay('Message 1');
		}

		public function avatarPreloader()
		{
			//Start Pre-Loader
			addChild(avatarLoading);
			avatarLoading.x = 500;
			avatarLoading.y = 300;
		}

		public function removeAvatar():void
		{
			if (getChildByName("Avatar") != null)
			{
				removeChild(getChildByName("Avatar"));
				SoundMixer.stopAll();
			}
		}

		private function sendPositions(avaPositionsX,avaPositionsY)
		{
			LoadAvaInPos(avaPositionsX,avaPositionsY,avatarLoader);
		}

		private function avatarLoaded(e:Event)
		{
			removeChild(avatarLoading);
		}

		private function setAvatarAndPosition(avatarURL:URLRequest,avaPositionsX:int,avaPositionsY:int,avatarToRemove:Boolean)
		{
			if (removeAvatar == true)
			{
				this.removeAvatar();
				trace("CourseFileNocturnalGame::setAvatarAndPosition - Removing avatar");
			}
			else
			{
				trace("CourseFileNocturnalGame::setAvatarAndPosition - Avatar = false");
			}
			sendPositions(avaPositionsX,avaPositionsY);
			avatarPreloader();
			avatarLoader.load(avatarURL);
			avatarLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, avatarLoaded);
		}

		private function pauseGame()
		{
			theCensus_mc.visible = false;
			instructionsHolder.visible = false;
			scoreBoard_mc.visible = false;
			progressBar_mc.visible = false;
		}

		private function resumeGame()
		{
			theCensus_mc.visible = true;
			instructionsHolder.visible = true;
			scoreBoard_mc.visible = true;
			progressBar_mc.visible = true;
		}

	}
}