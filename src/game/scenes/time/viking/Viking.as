package game.scenes.time.viking{
	import flash.display.DisplayObjectContainer;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Door;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.particles.emitter.Rain;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Candle;
	import game.scenes.time.viking.components.LightningFlash;
	import game.scenes.time.viking.systems.LightningFlashSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class Viking extends PlatformerGameScene
	{
		public function Viking()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/viking/";
			super.init(container);
		}
		
		override public function destroy():void
		{
			super.destroy();	
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_events = super.events as TimeEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);	
			this.addSystem(new LightningFlashSystem(), SystemPriorities.update);
			setUpExplodingRocks();
			var char:Entity = super.getEntityById("captain");
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( char );
			super.loaded();
			placeTimeDeviceButton();
			addRain();	
			addThunderAndLightning();
			
			if( super.shellApi.checkItemUsedUp(_events.AMULET))
			{
				SkinUtils.setSkinPart(char, SkinUtils.OVERSHIRT, "amulet",true);
				itemReturned = true;
			}
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}

			var entranceBlocked:Boolean = ! shellApi.checkEvent(_events.CAVE_OPEN);
			EntityUtils.setSleep(getEntityById("hiddenDoor"), entranceBlocked);
			
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{

			if(event == GameEvent.GOT_ITEM + _events.AMULET)
			{
				if( !itemReturned && !shellApi.checkHasItem(_events.AMULET))
				{
					var char:Entity = super.getEntityById("captain");
					CharUtils.setAnim(char, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char) ).ended.add( onCelebrateEnd );
					
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
					itemReturned = true;
				}
			}
			else if(event == _events.GUNPOWDER_PLACED)
			{
				explodeRocks();
			}
			else if(event == _events.CAVE_OPEN)
			{
				Timeline(explodingRocks.get(Timeline)).gotoAndStop("open");
				EntityUtils.setSleep(getEntityById("hiddenDoor"), false);
				addFire();
			}	
		}
		
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{
			var char:Entity = super.getEntityById("captain");
			SkinUtils.setSkinPart(char, SkinUtils.OVERSHIRT, "amulet",true);
		}
		
		private function setUpExplodingRocks():void
		{
			explodingRocks = TimelineUtils.convertClip(super._hitContainer["caveRocks"],this,explodingRocks);
			explodingRocks.add(new Display(super._hitContainer["caveRocks"]));
			var doorEnt:Entity = super.getEntityById("hiddenDoor");
			
			if(! shellApi.checkEvent(_events.CAVE_OPEN,shellApi.island)){
				Timeline(explodingRocks.get(Timeline)).gotoAndStop("closed");			
				if(shellApi.checkEvent(GameEvent.HAS_ITEM + _events.GUNPOWDER)){
					// add one time click interaction to plant gunpowder if player has it
					interaction = InteractionCreator.addToEntity(explodingRocks, [InteractionCreator.CLICK]);
					interaction.click.addOnce(placeGunpowder);
				}else{
					interaction = InteractionCreator.addToEntity(explodingRocks, [InteractionCreator.CLICK]);
					interaction.click.add( Command.create(rocksReached, doorEnt ));
				}
			}
			else
			{
				Timeline(explodingRocks.get(Timeline)).gotoAndStop("open");
				addFire();
			}
		}
		
		private function rocksReached( rocks:Entity, door:Entity):void
		{	
			if( shellApi.checkEvent(_events.CAVE_OPEN ))
			{
				// open
				Door( door.get( Door )).open = true;
			}
			else
			{
				// not open
				Dialog( player.get( Dialog )).sayById( "examine_rocks" );
			}
		}
		
		private function placeGunpowder(ent:Entity):void
		{
			shellApi.removeItem(_events.GUNPOWDER);
			shellApi.triggerEvent(_events.GUNPOWDER_PLACED);
		}
		
		private function explodeRocks():void
		{
			Timeline(explodingRocks.get(Timeline)).gotoAndPlay("closed");
			Timeline(explodingRocks.get(Timeline)).labelReached.add(clearDoorway);
		}
		
		private function clearDoorway(timer:String):void
		{
			// make particles
			addRockExplode();
			shellApi.triggerEvent(_events.CAVE_OPEN,true);
			shellApi.triggerEvent(_events.GUNPOWDER_EXPLODE);
		}
		
		private function addFire():void
		{
			var fire:Candle = new Candle();
			fire.init();
			EmitterCreator.create(this, super._hitContainer, fire, 2400, 714);
		}
		
		private function addRockExplode():void
		{
			var explode:FlameBlast = new FlameBlast();
			explode.counter = new Blast(3);
			explode.addInitializer(new Lifetime(0.2, 0.4));
			explode.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 300, 200, -Math.PI, 0 )));
			explode.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			explode.addInitializer(new ImageClass(Blob, [20,0x999999], true, 6));
			explode.addAction(new Age());
			explode.addAction(new Move());
			explode.addAction(new RotateToDirection());
			EmitterCreator.create(this, super._hitContainer, explode, 2420, 650);
		}
		
		private function addRain():void
		{			
			var rain:Rain = new Rain();
			rain.init(new Random(20, 30), new Rectangle(0, 0, this.shellApi.viewportWidth*2, this.shellApi.viewportHeight*2));
			var emitter:Entity = EmitterCreator.create(this, this._hitContainer, rain, -this.shellApi.viewportWidth, -this.shellApi.viewportHeight, null, "rain", this.player.get(Spatial));
		}
		
		private function addThunderAndLightning():void
		{
			lightningEnt = EntityUtils.createSpatialEntity(this, groupContainer);
			var lightningFlash:LightningFlash  = new LightningFlash();
			
			lightningFlash.delay = Math.random() * 10;
			lightningFlash.soundEvent = _events.THUNDER_CLAP;	
			lightningFlash.flashing = false;
			
			lightningFlash.startColorTrans = container.transform.colorTransform;
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = 0xE1E1E1;
			lightningFlash.flashingColorTrans = colorTransform;
			
			lightningEnt.add(lightningFlash);
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
		private var lightningEnt:Entity;
		private var explodingRocks:Entity;
		private var interaction:Interaction;
		private var _events:TimeEvents;
		private var itemReturned:Boolean = false;
	}
}