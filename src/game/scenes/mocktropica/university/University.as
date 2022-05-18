package game.scenes.mocktropica.university{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.Rain;
	import game.scenes.mocktropica.shared.*;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Steady;
	
	public class University extends MocktropicaScene
	{
		public function University()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/university/";
			
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
			
			super.shellApi.eventTriggered.add(handleEventTriggered);			

			var entity:Entity = new Entity();			
			entity.add(new Display(MovieClip(super._hitContainer).hourHand));
			entity.add(new Spatial());
			super.addEntity(entity);
			
			_adManager = super.getEntityById("adManager");
			
			var entitym:Entity = new Entity();			
			entitym.add(new Display(MovieClip(super._hitContainer).minuteHand));
			entitym.add(new Spatial());
			super.addEntity(entitym);
			
			_timeControlSystem = new ClockTimeSystem
			_timeControlSystem.init(entity, entitym);
			
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).horn_btn, this, handleHornButtonClicked, null, null, ToolTipType.CLICK);
			
			
			super.addSystem( _timeControlSystem, SystemPriorities.update );
			
			_adGroup = super.addChildGroup( new AdvertisementGroup( this, super._hitContainer )) as AdvertisementGroup;
			
			radioSoundEntity = new Entity();
			radioAudio = new Audio();
			radioAudio.play(SoundManager.MUSIC_PATH + "Short_Funky_Drum_Loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
			radioSoundEntity.add(radioAudio);
			radioSoundEntity.add(new Spatial(850, 1100));
			radioSoundEntity.add(new AudioRange(800, 0, 1, Quad.easeIn));
			radioSoundEntity.add(new Id("soundSource"));
			super.addEntity(radioSoundEntity);	
			
			
			var glitch:Entity = TimelineUtils.convertClip(MovieClip(super._hitContainer).statue_mc, this);
			var timeline:Timeline = glitch.get(Timeline);
			
			// If it should be raining turn the rain effect on
			if(super.shellApi.checkEvent(_events.SET_RAIN))
			{
				var rain:Rain = new Rain();
				rain.init(new Steady(50), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight), 2);
				EmitterCreator.createSceneWide(this, rain);
			}
			
			if(!this.shellApi.checkEvent(_events.DEVELOPER_RETURNED))
			{				
				var num:Number = (Math.random()*60) + 1
				timeline.gotoAndPlay(num);
			}else{
				timeline.gotoAndStop(1);
			}
			
			if(this.shellApi.checkEvent(_events.WRITER_LEFT_CLASSROOM) && !this.shellApi.checkEvent(_events.BOUGHT_ADS) )
			{				
				//show annoying popup ad
				showPopup();
			}
			
			if(this.shellApi.checkEvent(_events.WRITER_LEFT_CLASSROOM) && !this.shellApi.checkEvent(_events.SPOKE_SALES_MANAGER_AD) )
			{				
				Dialog(_adManager.get(Dialog)).sayById("obtrusiveAd");
			}			
			
			if (this.shellApi.checkEvent(_events.SET_DAY))
			{				
			}else {
				var fireEmitter:Fire = new Fire(); 
				EmitterCreator.create(this, MovieClip(super._hitContainer).fire_mc, fireEmitter, 0, 0 ); 
				fireEmitter.init();
			}
		}

		private function handleHornButtonClicked(entity:Entity):void	
		{
			super.shellApi.triggerEvent("hornClickSFX");
			
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "salesMangagerLeave")
			{
				var npc:Entity = super.getEntityById("adManager");
				CharUtils.moveToTarget(npc, -100, 1672, false);
				
				super.shellApi.triggerEvent( _events.SPOKE_SALES_MANAGER_AD, true );
			}
		}			
		
		private function showPopup():void
		{
			_adGroup.createAdvertisement( _events.ADVERTISEMENT_BOSS_3, completeAds);			
		}
		
		private function completeAds( ...args ):void
		{
//			// a hook for after the popup is finished to add scene code into
//			popup.close();
		}
		
		private var _events:MocktropicaEvents;
		private var radioSoundEntity:Entity;
		private var radioAudio:Audio;
		private var _timeControlSystem:ClockTimeSystem;
		private var _adManager:Entity;
		private var _adGroup:AdvertisementGroup;
		
	}
}