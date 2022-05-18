package game.scenes.virusHunter.cityLeft{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.MotionControl;
	import game.components.motion.Navigation;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Tremble;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.IntermittentSparks;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	//import org.flintparticles.twoD.zones.LineZone;
	//import org.flintparticles.twoD.zones.RectangleZone;
	
	public class CityLeft extends PlatformerGameScene
	{
		private var _leavesEntity:Entity;
		private var _vanEntity:Entity;
		private var _vanDoorEntity:Entity;
		private var _vanWheel1Entity:Entity;
		private var _vanWheel2Entity:Entity;
		private var _shreddedPaperEntity:Entity;
		private var _fliesEntity:Entity;
		private var _manWithShades:Entity;
		private var virusEvents:VirusHunterEvents;
		
		private var girl:Entity;
		private var dog:Entity;
		private var isMember:Boolean = false;
		
		public function CityLeft()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/cityLeft/";
			
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
			super.loaded();
			
			isMember = super.shellApi.profileManager.active.isMember;
			
			virusEvents = super.events as VirusHunterEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			_manWithShades = super.getEntityById("manWithShades");
			var shreddedPaperClip:MovieClip = MovieClip(super._hitContainer).shreddedPaper;
			_shreddedPaperEntity = TimelineUtils.convertClip( shreddedPaperClip, this );
			
			var timeline:Timeline = _shreddedPaperEntity.get(Timeline);
			timeline.handleLabel("land", playBagSound);
			
			//if ( super.shellApi.checkEvent(virusEvents.VAN_LEFT) ) {
			if ( super.shellApi.checkHasItem("shreddedDocuments") || !super.shellApi.checkEvent(virusEvents.TALKED_TO_BERT) ) {
				removeVan();
			}
			else {
				setVan();
			}
			
			//var emitter:BlowingLeaves = new BlowingLeaves(); 
			//_leavesEntity = EmitterCreator.create(this, super._hitContainer, emitter, 0, 0); 
			//emitter.init( new LineZone( new Point(0,super.sceneData.cameraLimits.bottom/2), new Point(0,super.sceneData.cameraLimits.bottom) ), new Point(300,50), new RectangleZone(super.sceneData.cameraLimits.left, super.sceneData.cameraLimits.top, super.sceneData.cameraLimits.right, super.sceneData.cameraLimits.bottom) );
			
			var fliesEmitter:SwarmingFlies = new SwarmingFlies();
			_fliesEntity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
			fliesEmitter.init(new Point(850, 1100));
			
			//positional flies sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_02_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(850, 1100));
			entity.add(new AudioRange(500, 0, 0.4, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			
			var sparks:IntermittentSparks = new IntermittentSparks();
			sparks.init();
			var sparksEntity:Entity = EmitterCreator.create(this, super._hitContainer, sparks, 1195, 410, null, "intermittentSparks");	
			var sparksSleep:Sleep = new Sleep();
			sparksSleep.zone = super.sceneData.bounds;
			sparksEntity.add(sparksSleep);
			
			this.setupDay2();
		}
		
		private function setupDay2():void
		{
			this.girl = this.getEntityById("girl");
			this.dog = this.getEntityById("dog");
			
			//Used before this was pushed live to prevent people from playing Day 2
			/*if(!this.shellApi.siteProxy.isTestServer())
			{
				if(girl) this.removeEntity(this.girl);
				if(dog) this.removeEntity(this.dog);
				return;
			}*/
			
			if(!this.shellApi.checkHasItem(this.virusEvents.MEDAL_VIRUS)) return;
			
			if(!this.shellApi.checkEvent(this.virusEvents.TALKED_TO_GIRL))
			{
				this.addSystem(new ThresholdSystem());
				this.shellApi.camera.target = this.girl.get(Spatial);
				
				this.girl.get(Spatial).x = 900;
				
				var threshold:Threshold = new Threshold("x", ">=");
				threshold.threshold = 1850;
				threshold.entered.addOnce(handleRun);
				this.girl.add(threshold);
				
				this.dog.add(new Audio());
				this.dog.add(new AudioRange(900));
				this.dogBark();
				
				SceneUtil.lockInput(this);
				
				CharUtils.followEntity(girl, dog);
				CharUtils.followPath(dog, new <Point>[new Point(2800, 1310)], handlePath, true);
				
				var interaction:SceneInteraction = this.girl.get(SceneInteraction);
				interaction.triggered.add(this.openBonusPopup);
			}
		}
		
		private function dogBark():void
		{
			var audio:Audio = this.dog.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "dog_bark_01.mp3", false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
		}
		
		private function openBonusPopup(player:Entity, girl:Entity):void
		{
			var blocker:BonusQuestPopup = this.addChildGroup(new BonusQuestPopup(this.overlayContainer)) as BonusQuestPopup;
			blocker.id = "bounsQuestPopup";
			blocker.popupRemoved.addOnce(loadScene);
		}
		
		private function loadScene(popup:Popup = null):void
		{
			if(!isMember) this.shellApi.loadScene(CityLeft);
			else
			{
				SceneUtil.lockInput(this);
				var interaction:SceneInteraction = this.girl.get(SceneInteraction);
				interaction.triggered.remove(this.openBonusPopup);
			}
		}
		
		private function handleRun():void
		{
			this.girl.remove(Threshold);
			this.removeSystemByClass(ThresholdSystem);
			this.dogBark();
			
			var dialog:Dialog = this.girl.get(Dialog);
			dialog.sayById("come_back");
			dialog.complete.addOnce(setCamera);
			CharUtils.stopFollowEntity(this.girl);
		}
		
		private function setCamera(data:DialogData):void
		{
			SceneUtil.lockInput(this, false);
			this.shellApi.camera.target = this.player.get(Spatial);
			
			/**
			 * The girl is losing her Tool Tip for some reason after the followPath().
			 * Gonna add it back in as a quick fix, but something's buggy.
			 */
			ToolTipCreator.addToEntity(this.girl);
		}
		
		private function handlePath(dog:Entity):void
		{
			this.removeEntity(this.dog);
			this.dog = null;
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "vanLeaves")
			{
				vanLeaves();
			}
			else if(event == "driverTrembles")
			{
				CharUtils.setAnim(_manWithShades, Tremble);
			}
			else if(event == virusEvents.TALKED_TO_GIRL)
			{
				SceneUtil.lockInput(this, false);
			}
		}
		
		private function playBagSound():void
		{
			super.shellApi.triggerEvent("playBagSound");
		}
		
		private function setVan():void
		{
			SceneInteraction(_manWithShades.get(SceneInteraction)).offsetX = 25;
			
			CharUtils.stateDrivenOff(_manWithShades, 99999);
			SceneInteraction(_manWithShades.get(SceneInteraction)).offsetY = 100;
			
			var vanClip:MovieClip = MovieClip(super._hitContainer).van;
			_vanEntity = EntityUtils.createMovingEntity(this, vanClip, super._hitContainer);
			
			var vanWheel1Clip:MovieClip = vanClip.wheel1;
			_vanWheel1Entity = EntityUtils.createMovingEntity(this, vanWheel1Clip, vanClip);
			var vanWheel2Clip:MovieClip = vanClip.wheel2;
			_vanWheel2Entity = EntityUtils.createMovingEntity(this, vanWheel2Clip, vanClip);
			
			var vanDoorClip:MovieClip = vanClip.door;
			_vanDoorEntity = TimelineUtils.convertClip( vanDoorClip, this );
			
			//super._hitContainer.setChildIndex(super.player.get(Display).displayObject, super._hitContainer.numChildren-1);
			
			super._hitContainer.setChildIndex(_vanEntity.get(Display).displayObject, 0);
			super._hitContainer.setChildIndex(_manWithShades.get(Display).displayObject, 0);
		}
		
		private function removeVan():void
		{
			super.removeEntity(_manWithShades);
			MovieClip(super._hitContainer).van.visible = false;
			TimelineClip(_shreddedPaperEntity.get(TimelineClip)).mc.visible = false;
		}
		
		private function vanLeaves():void
		{
			Timeline(_shreddedPaperEntity.get(Timeline)).playing = true;
			Timeline(_vanDoorEntity.get(Timeline)).playing = true;
			
			// NOTE :: Might want a cleaner way to remove all of this stuff
			_manWithShades.remove(FSMControl);
			_manWithShades.remove(AnimationControl);
			_manWithShades.remove(MotionControl);
			_manWithShades.remove(Navigation);
			
			_manWithShades.add( new Motion() );
			Motion(_manWithShades.get(Motion)).velocity = new Point(-100, 0);
			Motion(_manWithShades.get(Motion)).acceleration = new Point(-500, 0);
			
			Motion(_vanEntity.get(Motion)).velocity = new Point(-100, 0);
			Motion(_vanEntity.get(Motion)).acceleration = new Point(-500, 0);
			
			Motion(_vanWheel1Entity.get(Motion)).rotationVelocity = -100;
			Motion(_vanWheel1Entity.get(Motion)).rotationAcceleration = -500;
			
			Motion(_vanWheel2Entity.get(Motion)).rotationVelocity = -100;
			Motion(_vanWheel2Entity.get(Motion)).rotationAcceleration = -500;
			
			super.shellApi.completeEvent(virusEvents.VAN_LEFT);
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, moveToShreddedDocuments ) );
			
			super.shellApi.triggerEvent("playVanSound");
			super.shellApi.triggerEvent("playSlamSound");
		}
		
		private function moveToShreddedDocuments():void
		{
			CharUtils.moveToTarget(super.player, 320, super.sceneData.bounds.bottom, false, getShreddedDocuments);
		}
		
		private function getShreddedDocuments(entity:Entity):void
		{
			TimelineClip(_shreddedPaperEntity.get(TimelineClip)).mc.visible = false;
			super.shellApi.getItem("shreddedDocuments", null, true );
			SceneUtil.lockInput(this, false);
		}
	}
}