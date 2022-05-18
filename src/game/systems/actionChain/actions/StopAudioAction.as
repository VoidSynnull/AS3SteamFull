package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.AudioSystem;
	
	import game.data.TimedEvent;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	// Stop audio 
	public class StopAudioAction extends ActionCommand
	{
		private var target:Entity;
		private var soundUrl:String;
		private var group:Group;
		private var audioId:String;
		private var sceneMusic:Boolean;
		private var musicWrapperCurVolume:Number;
		private var ambientCurVolume:Number;
		private var resumeMusicDelay:Number;
		private var audioSystem:AudioSystem;
		
		/**
		 * Stop audio 
		 * @param target			Entity
		 * @param soundUrl			URL of sound file
		 * @param audioId			Audio ID
		 */
		public function StopAudioAction(target:Entity, soundUrl:String, audioId:String = null, sceneMusic:Boolean=false,resumeMusicDelay:Number=0) 
		{
			//TODO: need to detemine whether to kill sound from target entity or global sound entity
			this.target 			= target;
			this.soundUrl 			= soundUrl;
			this.audioId 			= audioId;
			this.sceneMusic		    = sceneMusic;
			this.resumeMusicDelay   = resumeMusicDelay;
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			this.group = group;
			if(sceneMusic)
			{
				var scene:Scene = group.shellApi.sceneManager.currentScene;
				audioSystem = AudioSystem(scene.getSystem(AudioSystem));
				audioSystem.unMuteSounds();
				musicWrapperCurVolume = audioSystem.getVolume("music");
				ambientCurVolume = audioSystem.getVolume("ambient");
				audioSystem.setVolume(0.001, "music");
				audioSystem.setVolume(0, "ambient");
				SceneUtil.addTimedEvent(scene,new TimedEvent( resumeMusicDelay, 1, resumeMusic));
			}
			else
				AudioUtils.stop(group, soundUrl, audioId);
			if( callback )
				callback();
		}
		
		private function resumeMusic():void
		{
			audioSystem.setVolume(musicWrapperCurVolume, "music");
			audioSystem.setVolume(ambientCurVolume, "ambient");
		}
	}
}