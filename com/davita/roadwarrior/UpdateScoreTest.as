﻿/*
Copyright (c) 2012 Normal Software.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.davita.roadwarrior
{
	import flash.display.*;
	import flash.events.*;
	import com.davita.events.ScorePollEvent;
	import com.davita.events.ScoreUpdatedEvent;
	import com.davita.events.ScoreSetEvent;


	/**
	 *  base class for davita standard game files.
	 *
	 * @langversion ActionScript 3
	 *@playerversion Flash 9.0.0
	 *
	 *@author Dean Hawkey
	 *@since  2012
	 */

	public dynamic class UpdateScoreTest extends MovieClip {;

	private var __courseWrapper:Object;
	private var _bookmarkMilesChallengesArray:Array;
	private var _bookmark:int;
	private var _challenges:int;
	private var _miles:int;
	private var _pageMask:Sprite = new Sprite();


	//---------------------------------------
	// CONSTRUCTOR
	//---------------------------------------
	public function UpdateScoreTest():void
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
		// find the wrapper and listen for a score updated event
		var success:Boolean = findWrapper();
		if(success)
		{
			__courseWrapper.addEventListener(ScoreUpdatedEvent.SCORE_UPDATED, updateScore, false, 0, true);
			dispatchEvent(new ScorePollEvent(ScorePollEvent.SCORE_POLLED));
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
				trace("UpdateScoreTest:: found the wrapper");
				return true;
				// Object(curParent).loader.addEventListener("unload", dispose, false, 0, true); 
			}
			curParent = curParent.parent;
		}
		trace("UpdateScoreTest:: not in a wrapper");
		return false;
	}

	private function maskPage():void
	{
		_pageMask.graphics.beginFill(0x000000);
		_pageMask.graphics.drawRect(0,.5,1000,599.5);
		addChild(_pageMask);
		this.mask = _pageMask;
	}

	private function updateScore(e:ScoreUpdatedEvent):void
	{
		trace("UpdateScoreTest::updateScore(" + e + ")");
		this._bookmarkMilesChallengesArray = e.bookmarkMilesChallengesArray;
		this._bookmark = this._bookmarkMilesChallengesArray[0];
		this._miles = this._bookmarkMilesChallengesArray[1];
		this._challenges = this._bookmarkMilesChallengesArray[2];
		this.dataTextField.text = e.toString();
	}

	private function setScore():void
	{
		this._bookmarkMilesChallengesArray = [this._bookmark, this._miles, this._challenges];
		dispatchEvent(new ScoreSetEvent(ScoreSetEvent.SCORE_SET, this._bookmarkMilesChallengesArray));
		trace("UpdateScoreTest::setScore:ScoreSetEvent(" + this._bookmarkMilesChallengesArray + ")");
	}

	//---------------------------------------
	// Public METHODS
	//---------------------------------------

	// Keep score
	public function addMiles(addedMiles:int):void
	{
		trace("UpdateScoreTest::addMiles(" + addedMiles + ")");
		this._miles = (this._miles + addedMiles);
		setScore();
	}

	public function addChallenges(addedChallenge:int):void
	{
		trace("UpdateScoreTest::addChallenges(" + addedChallenge + ")");
		this._challenges = (this._challenges + addedChallenge);
		setScore();
	}
}
}