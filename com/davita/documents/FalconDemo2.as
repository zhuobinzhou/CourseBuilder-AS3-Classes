﻿package com.davita.documents
{
	import flash.display.MovieClip;
	import com.greensock.TweenLite;
	import com.greensock.TimelineLite;
	import com.greensock.easing.*;
	import com.greensock.plugins.*;

	public class FalconDemo2 extends MovieClip
	{

		public function FalconDemo2()
		{
			super();
		}

		TweenPlugin.activate([GlowFilterPlugin, AutoAlphaPlugin, BlurFilterPlugin,TintPlugin, ColorTransformPlugin, VisiblePlugin]);


		// Functions to Bring in Objects;
		public function mainImageFadeIn(mc:MovieClip, delayTime1):void
		{
			stop();
			mc.alpha = 0;
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.to(mc, .2, {alpha:.9, colorTransform:{tint:0xffffff, tintAmount:0.4}}));
			timeline.append(TweenLite.to(mc, .2, {alpha:1, colorTransform:{exposure:1.9}}));
			timeline.append(TweenLite.to(mc, .25, {alpha:.9, colorTransform:{exposure:1}}));
			timeline.append(TweenLite.to(mc, .25, {delay:delayTime1}));
		}

		public function screenBounceIn(mc:MovieClip, delayTime2):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.from(mc, 1, {y:-334, ease:Elastic.easeOut, blurFilter:{blurX:5, blurY:5}}));
			timeline.append(TweenLite.to(mc, .25, {delay:delayTime2}));
		}

		public function bulletFadeIn(movieClips:Array, delayTime3):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			for (var i:int=0; i < movieClips.length; i++)
			{
				timeline.append(TweenLite.from(movieClips[i], .35, {alpha:0,x:"-105",y:"-15", scaleX:2.5, scaleY:2.5, blurFilter:{blurX:20, blurY:20}}));
				timeline.append(TweenLite.to(movieClips[i], .25, {glowFilter:{color:0xffffff, alpha:1, blurX:8, blurY:8, strength:1, remove:true, delay:.25}}));
			}
			timeline.append(TweenLite.delayedCall(delayTime3, play));
		}

		public function flyinFromLeft(mc:MovieClip, delayTime4):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.from(mc, 1, {x:-427, alpha:0,ease:Elastic.easeOut, blurFilter:{blurX:10, blurY:0}}));
			timeline.append(TweenLite.delayedCall(delayTime4, play));
		}

		public function flyinFromRight(mc:MovieClip, delayTime5):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.from(mc, 1, {x:1024, alpha:0,ease:Elastic.easeOut, blurFilter:{blurX:10, blurY:0}}));
			timeline.append(TweenLite.delayedCall(delayTime5, play));
		}

		public function textFadeIn(movieClips:Array, delayTime6):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			for (var i:int=0; i < movieClips.length; i++)
			{
				timeline.append(TweenLite.from(movieClips[i], .35, {alpha:0,x:"-105",y:"-15", scaleX:2.5, scaleY:2.5, blurFilter:{blurX:20, blurY:20}}));
				timeline.append(TweenLite.to(movieClips[i], .25, {glowFilter:{color:0xffffff, alpha:1, blurX:8, blurY:8, strength:1, remove:true, delay:.5}}));
			}
			timeline.append(TweenLite.delayedCall(delayTime6, play));
		}

		// Functions to remove Objects
		public function miscFadeOut(...movieClips):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			for (var i:int=0; i < movieClips.length; i++)
			{
				var nestedTimeline:TimelineLite = new TimelineLite();
				nestedTimeline.append(TweenLite.to(movieClips[i], .25, {alpha:.38, blurFilter:{blurX:10, blurY:10}}));
				nestedTimeline.append(TweenLite.to(movieClips[i], .25, {autoAlpha:0}));
				timeline.append(nestedTimeline);
			}

		}

		public function singleFadeOut(movieClip:MovieClip, delayTime8):void
		{
			stop();
			TweenLite.to(movieClip, 1, {x:1024, ease:Quad.easeOut, alpha:0, scaleX:.2, scaleY:.2});
			TweenLite.delayedCall(delayTime8, play)
		}
		
		public function simpleFadeInOut(movieClip:MovieClip, delayTime):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});   
			timeline.append(TweenLite.from(movieClip, 1, {alpha:0}));
			timeline.append(TweenLite.to(movieClip, 1, {alpha:1,delay:delayTime}));
			timeline.append(TweenLite.to(movieClip, 1, {alpha:0}));
			timeline.append(TweenLite.delayedCall(.5, play));
		}

		public function textFadeOut(movieClips:Array, delayTime9):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			for (var i:int=0; i < movieClips.length; i++)
			{
				var nestedTimeline:TimelineLite = new TimelineLite();
				nestedTimeline.append(TweenLite.to(movieClips[i], .25, {alpha:.38, blurFilter:{blurX:10, blurY:10}}));
				nestedTimeline.append(TweenLite.to(movieClips[i], .1, {autoAlpha:0}));
				timeline.append(nestedTimeline);
			}
			timeline.append(TweenLite.delayedCall(delayTime9, play));
		}

		// Move Objects

		public function bounceToPosition(mc:MovieClip, xPos, yPos, delayTime11):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.to(mc, 1.5, {x:xPos, y:yPos, alpha:1,ease:Elastic.easeOut}));
			timeline.append(TweenLite.to(mc, .25, {delay:delayTime11}));
		}

		public function addCallOut(mc:MovieClip, delayTime12):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.from(mc, .35, {alpha:0,x:1024, scaleX:2.5, scaleY:2.5, blurFilter:{blurX:20, blurY:20}}));
			timeline.append(TweenLite.to(mc, .25, {alpha:1,ease:Expo.easeInOut}));
			timeline.append(TweenLite.to(mc, .25, {delay:delayTime12}));
		}
		// And Scale

		public function scaleToPosition(mc:MovieClip, xPos, yPos, scale, delayTime13):void
		{
			stop();
			var timeline:TimelineLite = new TimelineLite({onComplete:play});
			timeline.append(TweenLite.to(mc, 1, {x:xPos, y:yPos, alpha:1, scaleX:scale, scaleY:scale, ease:Expo.easeInOut}));
			timeline.append(TweenLite.to(mc, .25, {delay:delayTime13}));
		}



	}

}