package game.scenes.custom
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.data.ads.AdTrackingConstants;
	import game.data.profile.ProfileData;
	import game.proxy.Connection;
	import game.scenes.hub.arcadeGame.ArcadeGame;
	import game.util.PlatformUtils;
	
	public class AdStartPopup extends AdBasePopup
	{
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set popup tupe to Start
			_popupType = AdTrackingConstants.TRACKING_START;
			super.init(container);
		}

		/**
		 * Setup specific popup buttons 
		 */
		override protected function setupPopup():void
		{
			// set up start button
			setupButton(super.screen["startButton"], startGame);
			setupInstructions();		
		}
		
		/**
		 * Start game 
		 * @param button
		 */
		protected function startGame(button:Entity):void
		{
			// play game first time
			playGame();
		}
		
		/**
		 * Set up instructions 
		 * @param button
		 */
		protected function setupInstructions():void
		{
			// set up  instructions based on platform (mobile - action button, web - spacebar)
			var web:MovieClip = super.screen["web"];
			var mobile:MovieClip = super.screen["mobile"];
			
			if(PlatformUtils.isMobileOS)
			{
				if(web != null)
					super.screen["web"].visible = false;
				if(mobile != null)
					super.screen["mobile"].visible = true;
			}
			else
			{
				if(web != null)
					super.screen["web"].visible = true;
				if(mobile != null)
					super.screen["mobile"].visible = false;
			}
		}
	}
}