package game.scenes.virusHunter.lungs.busCutScene
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cough;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.particles.emitter.CarExhaust;
	import game.scene.template.CharacterGroup;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class BusCutScene extends Popup
	{
		private var joe:Entity;
		private var bus:Sprite;
		private var busEntity:Entity;
		private var emitter:CarExhaust;
		
		public function BusCutScene(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/virusHunter/lungs/busCutScene/";
			super.init(container);
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("busCutScene.swf", "npcs.xml"));
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.screen = super.getAsset("busCutScene.swf", true) as MovieClip;
			// this loads the standard close button
			super.loadCloseButton();
			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			//super.layout.centerUI(super.screen.content);
			
			var scaleX:Number = this.shellApi.viewportWidth / 1294;
			var scaleY:Number = this.shellApi.viewportHeight / 651;
			var max:Number = Math.max(scaleX, scaleY);
			
			this.screen.content.width *= max;
			this.screen.content.height *= max;
			
			super.loaded();
			
			// load the characters into the the groupContainer instead of the hitContainer since this isn't a platformer scene with camera layers.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.screen.content, super.getData("npcs.xml"), allCharactersLoaded );
		}
		
		private function allCharactersLoaded():void
		{
			super.open();
			
			joe = super.getEntityById("joe");
			CharUtils.setScale(joe, 0.8);
			
			super.convertToBitmapSprite(super.screen.content.background);
			
			var wrapper:BitmapWrapper = super.convertToBitmapSprite(super.screen.content.bus);
			this.bus = wrapper.sprite;
			this.bus.parent.addChild(this.bus);
			//MovieClip(super.screen).setChildIndex(background, 0);
			
			bus.x = -3000;
			//bus.y += 25;
			busEntity = EntityUtils.createMovingEntity(this, bus);
			Motion(busEntity.get(Motion)).velocity = new Point(1500, 0);
			
			var followTarget:Spatial = busEntity.get(Spatial);
			emitter = new CarExhaust();
			emitter.init(followTarget);
			var emitterEntity:Entity = EmitterCreator.create(this, super.screen.content, emitter, 20, 500, busEntity, "smoke", followTarget);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, -1, startCough));
			
			//positional sound
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "car_drive_away_01.mp3", false);
			busEntity.add(audio);
			busEntity.add(new AudioRange(400, 0, 1, Quad.easeIn));
			busEntity.add(new Id("soundSource"));
		}
		
		private function startCough():void
		{
			CharUtils.setAnim(joe, Cough, false, 200);
			SceneUtil.addTimedEvent(this, new TimedEvent(2.8, -1, this.close));
		}
	}
}