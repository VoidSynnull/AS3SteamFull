package game.scenes.ghd.outerSpace
{
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.audio.HitAudio;
	import game.components.entity.character.Player;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.TargetEntity;
	import game.components.motion.WaveMotion;
	import game.components.scene.Vehicle;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scene.template.AudioGroup;
	import game.scene.template.GameScene;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.scenes.ghd.barren1.Barren1;
	import game.scenes.ghd.lostTriangle.LostTriangle;
	import game.scenes.ghd.mushroom1.Mushroom1;
	import game.scenes.ghd.prehistoric1.Prehistoric1;
	import game.scenes.ghd.shared.PlanetGenerator;
	import game.scenes.ghd.shared.RandomBMD;
	import game.scenes.ghd.shared.StarData;
	import game.scenes.ghd.shared.popups.galaxyMap.GalaxyMap;
	import game.systems.SystemPriorities;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.AccelerateToTargetRotationSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.motion.VehicleMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.ui.ButtonSystem;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	//Galaxy seed: SEED
	//System seed: SEED + star (x, y)
	//Planet seed: SEED + star (x, y) + planet (x, y)
	
	public class OuterSpace extends GameScene
	{
		public const MIN_NUM_PLANETS:uint = 4;
		public const MAX_NUM_PLANETS:uint = 20;
		public const LAND_COLORS:Array = [0xFF8AAB50, 0xFF97C8D2, 0xFFDEB06B, 0xFFE15011, 0xFFAC82D2, 0xFF846937, 0xFFC7CEC1, 0xFF589522, 0xFFBEB489, 0xFF717055, 0xFF58667A];
		public const WATER_COLORS:Array = [0xFF2F6580, 0xFF7BB9C6, 0xFFD67D43, 0xFF4D2215, 0xFF7558C0, 0xFF65492E, 0xFF9EA899, 0xFFB5D044, 0xFF3DA9D1, 0xFF9A9274, 0xFF8C8EA2];
		public const LAND_BLUR:BlurFilter = new BlurFilter(2, 2, 3);
		public const PLANET_DIAMETER:uint = 150;
		public const BASE_ORBIT_RADIUS:Number = 250;
		public const NUM_STARS:uint = 200;
		
		public var galaxySeed:uint;
		
		public var planetDagger:uint;
		public var planetHumphree:uint;
		public var planetCosmoe:uint;
		public var star:StarData;
		
		private var information:MovieClip;
		private var scanning:Boolean = false;
		private var ghdEvents:GalacticHotDogEvents;
		private var _events:GalacticHotDogEvents;
		
		public function OuterSpace()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/outerSpace/";
			_events = new GalacticHotDogEvents();
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			// save planet to userfield
			shellApi.setUserField( _events.PLANET_FIELD, _events.OUTER_SPACE, shellApi.island, true );
			
			this.ghdEvents = this.events as GalacticHotDogEvents;
			
			this.addSystem(new VehicleMotionSystem(), SystemPriorities.moveComplete);
			this.addSystem(new RotateToTargetSystem(), SystemPriorities.move);
			this.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);
			this.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);
			this.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			this.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			this.addSystem(new AccelerateToTargetRotationSystem(), SystemPriorities.move);
			this.addSystem(new NavigationSystem(), SystemPriorities.update);
			this.addSystem(new DestinationSystem(), SystemPriorities.update);	
			this.addSystem(new TargetEntitySystem(), SystemPriorities.update);
			this.addSystem(new ButtonSystem());
			this.addSystem(new BitmapSequenceSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new WaveMotionSystem());
			
			this.setupHUD();
			this.setupStars();
			this.setupWisps();
			this.setupSun();
			this.setupPlanets();
			this.setupPlayerShip();
			this.setupLostTriangle();
			this.setupInformationBar();
			this.setupGalaxyMapButton();
		}
		
		private function setupHUD():void
		{
			var hud:Hud = new shellApi.islandManager.hudGroupClass(this.overlayContainer);
			hud.ready.addOnce(this.onHUDReady);
			this.addChildGroup(hud);
		}
		
		private function onHUDReady(hud:Hud):void
		{
			hud.disableButton(Hud.COSTUMIZER);
			hud.disableButton(Hud.INVENTORY);
		}
		
		private function setupSun():void
		{
			var background:MovieClip = this._hitContainer["space"]["background"];
			var sunClip:MovieClip = this._hitContainer["sun"];
			
			sunClip.x = background.width / 2;
			sunClip.y = background.height / 2;
			
			var color:ColorTransform;
			
			color = sunClip["circle"]["color"].transform.colorTransform;
			color.color = star ? star.color : 0xFFFFFF;
			sunClip["circle"]["color"].transform.colorTransform = color;
			
			color = sunClip["glow"]["color"].transform.colorTransform;
			color.color = star ? star.color : 0xFFFFFF;
			sunClip["glow"]["color"].transform.colorTransform = color;
			
			var sun:Entity = EntityUtils.createSpatialEntity(this, sunClip);
			
			var sunSphere:Entity = EntityUtils.createMovingEntity(this, sunClip["circle"]);
			Motion(sunSphere.get(Motion)).rotationVelocity = 20;
			
			var sunGlow:Entity = EntityUtils.createSpatialEntity(this, sunClip["glow"]);
			sunGlow.add(new SpatialAddition());
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.add(new WaveMotionData("scaleX", 0.05, 3, "sin", 0, true));
			waveMotion.add(new WaveMotionData("scaleY", 0.05, 3, "sin", 1, true));
			waveMotion.add(new WaveMotionData("rotation", 5, 3, "sin", 0, true));
			sunGlow.add(waveMotion);
		}
		
		private function setupLostTriangle():void
		{
			var triangleClip:MovieClip = this._hitContainer["triangle"];
			
			if(this.shellApi.checkEvent(ghdEvents.LOOKING_FOR_LOST_TRIANGLE) && this.star && this.star.x == 529 && this.star.x == 529)
			{
				this.addSystem(new WaveMotionSystem());
				
				var reference:MovieClip = triangleClip["debris"];
				
				for(var index:int = 0; index < 8; ++index)
				{
					reference.gotoAndStop(index + 1);
					
					var sprite:Sprite = this.createBitmapSprite(reference, 1, null, true, 0, null, false);
					
					var debris:Entity = EntityUtils.createMovingEntity(this, sprite, triangleClip);
					
					var motion:Motion = debris.get(Motion);
					motion.rotationVelocity = Utils.randNumInRange(-100, 100);
					
					var magnitude:Number = Utils.randNumInRange(50, 150);
					var radians:Number = Utils.randNumInRange(0, Math.PI * 2);
					var rate:Number = Utils.randNumInRange(0.1, 1);
					
					var wave:WaveMotion = new WaveMotion();
					wave.add(new WaveMotionData("x", magnitude, rate, "cos", radians, true));
					wave.add(new WaveMotionData("y", magnitude, rate, "sin", radians, true));
					debris.add(wave);
					
					debris.add(new SpatialAddition());
				}
				
				var triangle:Entity = EntityUtils.createSpatialEntity(this, triangleClip);
				var interaction:Interaction = InteractionCreator.addToEntity(triangle, [InteractionCreator.CLICK]);
				interaction.click.add(loadLostTriangle);
				ToolTipCreator.addToEntity(triangle);
				
				reference.parent.removeChild(reference);
			}
			else
			{
				triangleClip.parent.removeChild(triangleClip);
			}
		}
		
		private function loadLostTriangle(entity:Entity):void
		{
			this.shellApi.loadScene(LostTriangle);
		}
		
		private function setupStars():void
		{
			var space:MovieClip = this._hitContainer["space"];
			var background:MovieClip = space["background"];
			var stars:MovieClip = space["stars"];
			var star:MovieClip = space["star"];
			
			stars.mouseChildren = false;
			stars.mouseEnabled = false;
			
			for(var index:int = 0; index < 200; ++index)
			{
				star.gotoAndStop(Utils.randInRange(1, star.totalFrames));
				
				var bitmap:Bitmap = this.createBitmap(star, 1, null, true, 0, false);
				bitmap.rotation = Utils.randNumInRange(0, 360);
				bitmap.x = Utils.randNumInRange(0, background.width) - bitmap.width / 2;
				bitmap.y = Utils.randNumInRange(0, background.height) - bitmap.height / 2;
				stars.addChild(bitmap);
			}
			
			star.parent.removeChild(star);
		}
		
		private function setupWisps():void
		{
			var space:MovieClip = this._hitContainer["space"];
			var background:MovieClip = space["background"];
			var wisps:MovieClip = space["wisps"];
			var wisp:MovieClip = space["wisp"];
			
			wisps.mouseChildren = false;
			wisps.mouseEnabled = false;
			
			for(var index:int = 0; index < 50; ++index)
			{
				wisp.gotoAndStop(Utils.randInRange(1, wisp.totalFrames));
				
				var bitmap:Bitmap = this.createBitmap(wisp, 1, null, true, 0, false);
				bitmap.rotation = Utils.randNumInRange(0, 360);
				bitmap.x = Utils.randNumInRange(0, background.width) - bitmap.width / 2;
				bitmap.y = Utils.randNumInRange(0, background.height) - bitmap.height / 2;
				wisps.addChild(bitmap);
			}
			
			wisp.parent.removeChild(wisp);
		}
		
		private function setupPlanets():void
		{
			var space:MovieClip = this._hitContainer["space"];
			var background:MovieClip = space["background"];
			var sun:MovieClip = this._hitContainer["sun"];
			
			space.mouseChildren = true;
			background.mouseEnabled = false;
			background.mouseChildren = false;
			
			var systemSeed:uint = this.galaxySeed;
			if(this.star) systemSeed += star.x + star.y;
			
			//Columns are planets, rows are info on them.
			//1 extra column is for numPlanets
			var data:BitmapData = new BitmapData(MAX_NUM_PLANETS + 1, 2, false, 0);
			data.noise(systemSeed);
			
			var numPlanets:uint = RandomBMD.integer(data, MAX_NUM_PLANETS, 0, MIN_NUM_PLANETS, MAX_NUM_PLANETS);
			
			var planetGenerator:PlanetGenerator = new PlanetGenerator();
			
			for(var index:int = numPlanets - 1; index > -1; --index)
			{
				var radians:Number = RandomBMD.number(data, index, 0, 0, Math.PI * 2);
				var length:Number = RandomBMD.number(data, index, 1, 310, 1400);
				
				var x:int = 1500 + length * Math.cos(radians);
				var y:int = 1500 + length * Math.sin(radians);
				
				var planetSeed:uint = systemSeed + x + y;
				
				var sprite:Sprite = planetGenerator.create(planetSeed);
				sprite.x = x;
				sprite.y = y;
				space.addChild(sprite);
				
				this.checkPlanetForFriend(planetSeed, sprite);
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
				
				var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
				interaction.click.add(onPlanetClick);
				
				ToolTipCreator.addToEntity(entity);
			}
		}
		
		private function checkPlanetForFriend(planetSeed:uint, planet:Sprite):void
		{
			if(planetSeed == this.planetCosmoe && this.shellApi.checkEvent(ghdEvents.FOUND_PLANET_PREHISTORIC))
			{
				highlightPlanet(planet, true);
			}
			else if(planetSeed == this.planetDagger && this.shellApi.checkEvent(ghdEvents.FOUND_PLANET_BARREN))
			{
				highlightPlanet(planet, true);
			}
			else if(planetSeed == this.planetHumphree && this.shellApi.checkEvent(ghdEvents.FOUND_PLANET_MUSHROOM))
			{
				highlightPlanet(planet, true);
			}
		}
		
		private function highlightPlanet(planet:Sprite, foundNPC:Boolean):void
		{
			var shape:Shape = planet.getChildByName("scanned") as Shape;
			if(!shape)
			{
				shape = new Shape();
				shape.name = "scanned";
				shape.graphics.lineStyle(5, foundNPC ? 0x00FF00 : 0xFF0000, 0.5);
				shape.graphics.drawCircle(0, 0, planet.width / 2 + 10);
				planet.addChild(shape);
			}
		}
		
		private function onPlanetClick(entity:Entity):void
		{
			var planet:Sprite = Display(entity.get(Display)).displayObject;
			
			if(planet.getChildByName("scanned"))
			{
				this.canTravelToPlanet(entity);
			}
			else if(!this.scanning)
			{
				this.scanning = true;
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "scan_01.mp3", 1, false, [SoundModifier.EFFECTS]);
				
				SceneUtil.setCameraTarget(this, entity);
				
				var spatial:Spatial = entity.get(Spatial);
				trace(spatial.x, spatial.y);
				
				var tween:Tween = this.getGroupEntityComponent(Tween);
				
				this.information.gotoAndStop(2);
				
				var clip:MovieClip = this.information.loader;
				clip.scaleX = 0;
				tween.to(clip, 2, {scaleX:1, ease:Linear.easeNone, onComplete:onScanComplete, onCompleteParams:[entity]});
			}
		}
		
		private function canTravelToPlanet(entity:Entity):Boolean
		{
			var spatial:Spatial = entity.get(Spatial);
			var planet:Sprite = Display(entity.get(Display)).displayObject;
			
			var planetSeed:uint = this.galaxySeed;
			if(this.star) planetSeed += this.star.x + this.star.y;
			planetSeed += spatial.x + spatial.y;
			
			if(planetSeed == this.planetDagger)
			{
				//Complete event in case players go to space faster than the friend messages in the galaxy map come up.
				this.shellApi.completeEvent(_events.FOUND_TRANSMISSION_DAGGER);
				this.foundFriendPlanet(planet, "barren", Barren1);
				return true;
			}
			else if(planetSeed == this.planetHumphree)
			{
				//Complete event in case players go to space faster than the friend messages in the galaxy map come up.
				this.shellApi.completeEvent(_events.FOUND_TRANSMISSION_HUMPHREE);
				this.foundFriendPlanet(planet, "mushroom", Mushroom1);
				return true;
			}
			else if(planetSeed == this.planetCosmoe)
			{
				//Complete event in case players go to space faster than the friend messages in the galaxy map come up.
				this.shellApi.completeEvent(_events.FOUND_TRANSMISSION_COSMOE);
				this.foundFriendPlanet(planet, "prehistoric", Prehistoric1);
				return true;
			}
			return false;
		}
		
		private function onScanComplete(entity:Entity):void
		{
			if(!this.canTravelToPlanet(entity))
			{
				this.information.gotoAndStop(3);
				this.highlightPlanet(Display(entity.get(Display)).displayObject, false);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, selectPlanetInfo));
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_17.mp3", 1, false, [SoundModifier.EFFECTS]);
			}
			
			SceneUtil.setCameraTarget(this, this.getEntityById("ship"));
		}
		
		private function foundFriendPlanet(planet:Sprite, planetName:String, sceneClass:Class):void
		{
			if(!this.shellApi.checkEvent(ghdEvents.FOUND_PLANET_ + planetName))
			{
				this.shellApi.completeEvent(ghdEvents.FOUND_PLANET_ + planetName);
				
				this.information.gotoAndStop(4);
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "panel_access_02.mp3", 1, false, [SoundModifier.EFFECTS]);
				this.highlightPlanet(planet, true);
				
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(this.loadPlanet, sceneClass)));
			}
			else
			{
				this.loadPlanet(sceneClass);
			}
		}
		
		private function loadPlanet(sceneClass:Class):void
		{
			// NOTE :: Don't think we need to wait for response from server to load next scene
			this.shellApi.loadScene(sceneClass);
		}
		
		private function selectPlanetInfo():void
		{
			this.scanning = false;
			this.information.gotoAndStop(1);
		}
		
		private function setupPlayerShip():void
		{
			var ship:Entity = new Entity();
			this.addEntity(ship);
			
			var shipClip:MovieClip = this._hitContainer["ship"];
			
			ship.add(new Spatial());
			EntityUtils.syncSpatial(ship.get(Spatial), shipClip);
			ship.add(new Display(shipClip));
			ship.add(new Id("ship"));
			ship.add(new Edge(-20, -20, 40, 40));
			ship.add(new RadialCollider());
			ship.add(new SceneCollider());
			ship.add(new ZoneCollider());
			ship.add(new CurrentHit());
			ship.add(new Audio());
			ship.add(new HitAudio());
			ship.add(new MotionControl());
			ship.add(new Player());
			ship.add(new MotionTarget());
			ship.add(new Navigation());
			ship.add(new MotionBounds(this.sceneData.bounds));
			
			var bitmapCollider:BitmapCollider = new BitmapCollider();
			bitmapCollider.addAccelerationToVelocityVector = true;
			ship.add(bitmapCollider);
			
			var motion:Motion 			= new Motion();
			motion.maxVelocity 			= new Point(300, 300);
			motion.friction 			= new Point();
			motion.rotationFriction 	= 30;
			motion.rotationMaxVelocity 	= 100;
			ship.add(motion);
			
			var accelerateToTargetRotation:AccelerateToTargetRotation 	= new AccelerateToTargetRotation();
			accelerateToTargetRotation.rotationAcceleration 			= 200;
			accelerateToTargetRotation.deadZone 						= 10;
			ship.add(accelerateToTargetRotation);
			
			var motionControlBase:MotionControlBase 			= new MotionControlBase();
			motionControlBase.acceleration 						= 800;
			motionControlBase.stoppingFriction 					= 300;
			motionControlBase.accelerationFriction 				= 0;
			motionControlBase.freeMovement 						= true;
			motionControlBase.rotationDeterminesAcceleration 	= true;
			motionControlBase.moveFactor 						= 0.3;
			ship.add(motionControlBase);
			
			var targetEntity:TargetEntity 	= new TargetEntity();
			targetEntity.target 			= this.shellApi.inputEntity.get(Spatial);
			targetEntity.applyCameraOffset 	= true;
			ship.add(targetEntity);
			
			var vehicle:Vehicle = new Vehicle();
			vehicle.onlyRotateOnAccelerate = true;
			ship.add(vehicle);
			
			AudioGroup(this.getGroupById(AudioGroup.GROUP_ID)).addAudioToEntity(ship);
			
			SceneUtil.setCameraTarget(this, ship);
			
			this.shellApi.camera.camera.scaleMotionTarget = motion;
			this.shellApi.camera.camera.scaleByMotion = true;
			this.shellApi.camera.camera.minCameraScale = 0.5; //Zoomed out
			this.shellApi.camera.camera.maxCameraScale = 0.7; //Zoomed in
			
			var emitter2D:Emitter2D = new Emitter2D();
			
			emitter2D.counter = new Random(4, 8);
			emitter2D.addInitializer(new ImageClass(Blob, [10]));
			emitter2D.addInitializer(new Lifetime(2, 3));
			
			emitter2D.addAction(new Age());
			emitter2D.addAction(new Move());
			emitter2D.addAction(new RandomDrift(50, 50));
			emitter2D.addAction(new ScaleImage(0.5, 1.5));
			emitter2D.addAction(new Fade(0.5, 0));
			emitter2D.addAction(new ColorChange(0x00FFFF, 0x666666));
			
			var particles:Entity = EmitterCreator.create(this, this._hitContainer, emitter2D, 0, 0, null, "thrusters", ship.get(Spatial));
			var shipIndex:int = shipClip.parent.getChildIndex(shipClip);
			shipClip.parent.setChildIndex(Display(particles.get(Display)).displayObject, shipIndex);
		}
		
		private function setupGalaxyMapButton():void
		{
			var display:DisplayObjectContainer = this._hitContainer["galaxyMapButton"];
			display.x = 80;
			display.y = this.shellApi.viewportHeight - 80;
			this.overlayContainer.addChild(display);
			
			ButtonCreator.createButtonEntity(display, this, openGalaxyMapPopup, null, null, null, true, true);
		}
		
		private function openGalaxyMapPopup(entity:Entity):void
		{
			this.addChildGroup(new GalaxyMap(this.overlayContainer));
		}
		
		private function setupInformationBar():void
		{
			this.information = this._hitContainer["information"];
			this.information.gotoAndStop(1);
			this.information.x = 0;
			this.information.y = this.shellApi.viewportHeight - this.information.height + 10;
			this.overlayContainer.addChild(this.information);
		}
	}
}