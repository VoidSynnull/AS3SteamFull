package game.scenes.time.lewis{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.input.Input;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Lewis extends PlatformerGameScene
	{
		private var beaver:Entity;
		private var beaverZone:Entity;
		private var hidingBeaver:Boolean = false;
		private var input:Input;
		private var tEvents:TimeEvents;
		private var _fire:Fire;
		private var _smoke:FireSmoke;
		
		public function Lewis()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/lewis/";
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
			setupHidingBeaver();
			tEvents = TimeEvents(events);
			super.loaded();
			placeTimeDeviceButton();
			setupFire();
			var char:Entity = super.getEntityById("lewis");			
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( char );
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			if( super.shellApi.checkEvent( tEvents.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + tEvents.SILVER_MEDAL)
			{
				if(!shellApi.checkHasItem(tEvents.SILVER_MEDAL) && !_returnedBool)
				{
					_returnedBool = true;
					shellApi.triggerEvent(tEvents.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
										
					// kill rope platform out of lewis's jump path for a bit
					getEntityById("rope").remove(Platform);
					
					var char:Entity = super.getEntityById("lewis");
					CharUtils.setAnim(char, Score);
					RigAnimation( CharUtils.getRigAnim( char) ).ended.add( onCelebrateEnd );
				}
			}
		}

		private function onCelebrateEnd( anim:Animation = null ):void
		{
			var char2:Entity = super.getEntityById("lewis");
			CharUtils.setAnim(char2, Stand, false, 0, 0, true);
			
			// put ropes back
			getEntityById("rope").add(new Platform());
		}
		
		public function setupHidingBeaver():void
		{
			if(! shellApi.checkEvent(GameEvent.GOT_ITEM + tEvents.STONE_BOWL)){
				beaver = EntityUtils.createSpatialEntity(this,_hitContainer["beaverBowl"]);
				beaver = TimelineUtils.convertClip(super._hitContainer["beaverBowl"],this,beaver);
				ToolTipCreator.addToEntity(beaver);
				(beaver.get(Timeline)as Timeline).gotoAndStop("up");
				// make hit zone
				beaverZone = super.getEntityById("beaver_zone1");
				var zone:Zone = beaverZone.get(Zone);
				zone.pointHit = true;
				zone.entered.addOnce(hitBeaver);	
				//listenForInput
				input = shellApi.inputEntity.get( Input ) as Input;
				input.inputDown.addOnce( delayedHide );
				input = SceneUtil.getInput( this );
				ToolTipCreator.addUIRollover(beaverZone,ToolTipType.CLICK);
				beaverZone.add(new Sleep());
			}
			else
			{
				beaver = TimelineUtils.convertClip(super._hitContainer["beaverBowl"],this);
				(beaver.get(Timeline)as Timeline).gotoAndStop("hidden");
			}
		}
		
		// delay hidig of the beaver so player has a real chance to grab it
		private function delayedHide(input:Input):void
		{
			hidetimer = SceneUtil.addTimedEvent(this, new TimedEvent(0.7,1,Command.create(hideBeaver,input)), "hidetimer");
		}
		
		private function hideBeaver( input:Input ):void
		{
			// animate hiding, and stop at end
			Timeline(beaver.get(Timeline)).gotoAndPlay("hide");
			Timeline(beaver.get(Timeline)).labelReached.add(showBeaver);
			// shut off hit
			setSleep(beaverZone, true);
			playBeaverSound();
		}
		
		private function removeBeaver():void
		{
			// hide
			input.inputDown.remove(delayedHide);
			if(hidetimer){
				hidetimer.stop();
			}
			Timeline(beaver.get(Timeline)).labelReached.remove(showBeaver);
			(beaver.get(Timeline)as Timeline).gotoAndStop("hidden");
			// shut off hit
			setSleep(beaverZone, true);
			playBeaverSound();
		}
		
		private function showBeaver(label:String):void
		{
			if(label == "hidden"){
				// animate re-appearing
				(beaver.get(Timeline)as Timeline).gotoAndPlay("appear");
				// resethiding
				input.inputDown.addOnce(delayedHide);
				// turn on hit
				setSleep(beaverZone, false);
			}
		}
		private function playBeaverSound():void
		{			
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "pop_02.mp3", false, SoundModifier.POSITION, 5);			
			beaver.add(audio);
			beaver.add(new AudioRange(1000, 0.01, 1, Quad.easeIn));
		}
		
		private function setSleep( entity:Entity, sleeping:Boolean = true):void
		{
			var sleep:Sleep = entity.get(Sleep);
			if(sleep == null){
				entity.add( new Sleep());
				sleep = entity.get(Sleep);
			}
			entity.get(Sleep).sleeping = sleeping;
			entity.get(Sleep).ignoreOffscreenSleep = sleeping;
		}
		
		private function hitBeaver( zoneId:String, characterId:String ):void
		{
			removeBeaver();
			shellApi.getItem(tEvents.STONE_BOWL,"time",true);
		}
		
		public function setupFire():void
		{
			var name:String = "fireInteraction";
			_fire = new Fire();
			_fire.init(5, new RectangleZone(-13, -4, 13, -4));
			EmitterCreator.create(this, this._hitContainer[name], _fire);
			_smoke = new FireSmoke();
			_smoke.init(9, new LineZone(new Point(-2, -20), new Point(2, -40)), new RectangleZone(-10, -5, 10, -5));
			EmitterCreator.create(this, this._hitContainer[name], _smoke);			
			var fireEnt:Entity = getEntityById(name);
			SceneInteraction(fireEnt.get(SceneInteraction)).reached.add(fireComment);
		}
		
		private function fireComment(entity:Entity, ent2:Entity):void{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("fireHot");
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		private var timeButton:Entity;
		private var _returnedBool:Boolean = false;
		private var hidetimer:TimedEvent;
	}
}