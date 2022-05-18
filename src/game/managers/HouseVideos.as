package game.managers
{
	import flash.external.ExternalInterface;
	import flash.system.Security;
	
	import ash.core.Entity;
	
	import engine.group.Scene;
	import engine.systems.AudioSystem;
	
	import game.scenes.hub.theater.MobileVideos;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.utils.AdUtils;

	/**
	 * To play house videos in main street ad unit, town scene and theater
	 * @author Rick Hocker
	 */
	public class HouseVideos 
	{
		private var _scene:Scene;
		private var _tracking:String;
		
		public function HouseVideos(scene:Scene, tracking:String) 
		{
			_scene = scene;
			_tracking = tracking;
			if (ExternalInterface.available)
			{
				Security.allowDomain("*");
				ExternalInterface.addCallback("playwireVideoDone", videoDone);
			}
		}
		
		// play playwire videos
		public function playVideos(button:Entity = null):void
		{
			// stop audio
			var audioSystem:AudioSystem = AudioSystem(_scene.getSystem(AudioSystem));
			audioSystem.muteSounds();
			// pause game
			SceneUtil.lockInput(_scene, true);
			_scene.pause(true, true);
			
			// if mobile
			if (PlatformUtils.isMobileOS)
			{
				// if network available, then load PlayWire mobile videos
				if (_scene.shellApi.networkAvailable())
					new MobileVideos(_scene.shellApi, videoDone);
			}
			// if web
			else
			{
				// send message to page
				if (ExternalInterface.available)
				{
					ExternalInterface.call("playwireVideo");
					_scene.shellApi.track(_tracking, "VideoClick", _scene.id);
				}
				else
				{
					videoDone();
				}
			}
		}
		
		// when playwire video done
		private function videoDone(credits:int = 5, hasContent:String = ""):void
		{
			// restore audio
			var audioSystem:AudioSystem = AudioSystem(_scene.getSystem(AudioSystem));
			audioSystem.unMuteSounds();
			// unpause
			SceneUtil.lockInput(_scene, false);
			_scene.unpause(true, true);
			
			// award credits
			if (credits != 0)
			{
				_scene.shellApi.profileManager.active.credits += credits;
				_scene.shellApi.profileManager.save();
				// show coins
				SceneUtil.getCoins(_scene, Math.round(credits/5));
				// save to database
				AdUtils.setScore(_scene.shellApi, credits, "housevideo");
			}
			if (hasContent == "false")
			{
				_scene.shellApi.track(_tracking, "VideoFail", _scene.id);
			}
			else
			{
				_scene.shellApi.track(_tracking, "VideoClose", _scene.id);
			}
		}
	}
}
