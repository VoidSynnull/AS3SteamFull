package game.scenes.examples.multiplayerExample
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.SpatialAddition;
	
	import game.components.entity.Dialog;
	import game.components.motion.WaveMotion;
	import game.creators.ui.ButtonCreator;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Grief;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SFSceneGroup;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.TweenUtils;
	
	public class MultiplayerExample extends PlatformerGameScene
	{
		public function MultiplayerExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/multiplayerExample/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// turn this scene into a multiplayer scene
			shellApi.sceneManager.enableMultiplayer();
			
			// listen for objects recieved
			var sfSceneGroup:SFSceneGroup = this.getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			sfSceneGroup.objectRecieved.add(onObjectRecieved); 
			
			// setup earthquake button
			_eqButton = ButtonCreator.createButtonEntity(_hitContainer["shakeButton"], this, sendEarthQuake, _hitContainer); 
			
			super.loaded();
		}
		
		private function sendEarthQuake(...p):void{
			trace(" ---> Sending an object to the server");
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			sfSceneGroup.shareObject({sceneFunction:"earthquake"});
		}
		
		private function onObjectRecieved(obj:Object, whoSentIt:Entity):void{
			trace(" <--- Recieved an object from server");
			if(obj.hasOwnProperty("sceneFunction")){
				this[obj.sceneFunction](whoSentIt);
			}
		}
		
		private function earthquake(whoSentIt:Entity):void{
			Dialog(whoSentIt.get(Dialog)).say("EARTHQUAKE!"); // have player who sent the object yell, "EARTHQUAKE!"
			cameraShake(); // shake scene
			
			// have all other players react
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			for each(var player:Entity in sfSceneGroup.allSFPlayers()){
				if(player != whoSentIt)
					CharUtils.setAnim(player, Grief);
			}
		}
		
		private function cameraShake():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion= cameraEntity.get(WaveMotion);
			
			if(waveMotion != null)
			{
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
			} else {
				waveMotion = new WaveMotion();
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 3;
			waveMotionData.rate = 0.5;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			TweenUtils.globalTo(this, waveMotionData, 3, {magnitude:0});
			
			if(!super.hasSystem(WaveMotionSystem)){
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
			
		}
		
		private var _eqButton:Entity;
	}
}