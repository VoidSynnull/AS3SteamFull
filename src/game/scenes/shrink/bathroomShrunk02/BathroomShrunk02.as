package game.scenes.shrink.bathroomShrunk02
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.EntityIdList;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.Wall;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.render.LightOverlay;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.item.UseItemData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.scenes.backlot.sunriseStreet.Systems.EarthquakeSystem;
	import game.scenes.backlot.sunriseStreet.components.Earthquake;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.bathroomShrunk02.BathWaterSystem.SoapyWater;
	import game.scenes.shrink.bathroomShrunk02.BathWaterSystem.SoapyWaterSystem;
	import game.scenes.shrink.bathroomShrunk02.FlusherSystem.Flusher;
	import game.scenes.shrink.bathroomShrunk02.FlusherSystem.FlusherSystem;
	import game.scenes.shrink.livingRoomShrunk.Particles.Bubbles;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDial;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDialSystem;
	import game.scenes.shrink.shared.Systems.WalkToTurnTimeline.WalkToTurnTimeline;
	import game.scenes.shrink.shared.Systems.WalkToTurnTimeline.WalkToTurnTimelineSystem;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.systems.SystemPriorities;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.popup.OneShotPopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class BathroomShrunk02 extends ShrinkScene
	{
		public function BathroomShrunk02()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/bathroomShrunk02/";
			
			super.init(container);
		}
		
		private var shrink:ShrinkEvents;
		private const TUB_FILLED_HEIGHT:Number = 875;
		private const TUB_EMPTY_HEIGHT:Number = 1075;
		
		private const DUCK_DENSITY:Number 		= .25;
		private const PLAYER_WEIGHT:Number 		= .45;
		private const BUOYANCY_DAMPENER:Number 	= .12;
		private const MAX_Y_VEL:Number 			= 250;
		
		private var tubWater:Entity;
		private var waterMover:Mover;
		
		private var villain:Entity;
		
		private var _sceneObjectCreator:SceneObjectCreator;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			shrink = events as ShrinkEvents;
			_sceneObjectCreator = new SceneObjectCreator();
			
			addSystem(new SceneObjectHitRectSystem());
			addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setUpVillain();
			setUpTub();
			setUPToilet();
			
			useableItems[shrink.THUMB_DRIVE] = new UseItemData(useThumbDrive,true,"no_point_thumb_drive"
				,shrink.BACKED_UP_THUMB_DRIVE,"back_up_thumb_drive",false,"dumpDrive", 250);
		}
		
		override public function useThumbDrive():void
		{
			if(!shellApi.checkEvent(shrink.GOT_CJS_MESSAGE_01))
			{
				Dialog(player.get(Dialog)).sayById("no_point_thumb_drive");
				return;
			}
			shellApi.removeItem(shrink.THUMB_DRIVE);
			Dialog(player.get(Dialog)).sayById("thumb_drive_in_toilet");
			shellApi.completeEvent(shrink.THUMB_DIRVE_IN_TOILET);
		}
		
		private function setUpVillain():void
		{
			villain = getEntityById("char1");
			villain.remove(Sleep);
			var clip:MovieClip = _hitContainer["largeShadow"];
			var shadow:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			shadow.add(new Id("villainShadow"));
		}
		
		private function setUPToilet():void
		{
			var clip:MovieClip = _hitContainer["flush_mc"];
			var flusher:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			Spatial(flusher.get(Spatial)).rotation = 5;
			
			DisplayUtils.moveToTop(_hitContainer["toilet_mc"]);
			DisplayUtils.moveToTop(_hitContainer["shadowsVector"]);
			
			clip = _hitContainer["flush_hit"];
			var flushCollider:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var follow:FollowTarget = new FollowTarget(flusher.get(Spatial),1,false,true);
			follow.offset = new Point(-20, -15);
			follow.properties = new Vector.<String>();
			follow.properties.push("x","y","rotation");
			flushCollider.add(new Platform()).add(follow).add(new EntityIdList());
			Display(flushCollider.get(Display)).alpha = 0;
			
			flusher.add(new Flusher(flushCollider.get(Platform)));
			Flusher(flusher.get(Flusher)).entityIdList = flushCollider.get(EntityIdList);
			Spatial(flusher.get(Spatial)).rotation = Flusher(flusher.get(Flusher)).up;
			Flusher(flusher.get(Flusher)).flush.add(flush);
			
			clip = _hitContainer["dumpDrive"];
			var dumpDrive:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			dumpDrive.add(new Id("dumpDrive"));
			Display(dumpDrive.get(Display)).alpha = 0;
			
			// IF WE NEED THE LIGHTS OFF
			if( shellApi.checkEvent(shrink.BATHROOM_LIGHTS_OFF))
			{
				// setup Foreground cover
				var lightOverlay:Sprite = new Sprite();
				super.overlayContainer.addChildAt(lightOverlay, 0);
				lightOverlay.mouseEnabled = false;
				lightOverlay.mouseChildren = false;
				lightOverlay.graphics.clear();
				lightOverlay.graphics.beginFill( 0x262626, .75 );
				lightOverlay.graphics.drawRect(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
				
				var display:Display = new Display(lightOverlay);
				display.isStatic = true;
				
				var lightOverlayEntity:Entity = new Entity();
				lightOverlayEntity.add(new Spatial());
				lightOverlayEntity.add(display);
				lightOverlayEntity.add(new Id("lightOverlay"));
				lightOverlayEntity.add(new LightOverlay( 0x262626, .75 ));
				
				super.addEntity( lightOverlayEntity );
			}
			
			clip = _hitContainer["newspaper"];
			var newspaper:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var interaction:Interaction = InteractionCreator.addToEntity(newspaper, ["click"],clip);
			interaction.click.add(readPaper);
			ToolTipCreator.addToEntity(newspaper);
			Display(newspaper.get(Display)).alpha = 0;
			
			addSystem(new FlusherSystem());
		}
		
		private function readPaper(paper:Entity):void
		{
			var popup:Group = addChildGroup(new OneShotPopup(overlayContainer, "passwordhint_popup.swf", groupPrefix, false));
			popup.removed.add(commentOnArticle);
		}
		
		private function commentOnArticle(...args):void
		{
			Dialog(player.get(Dialog)).sayById("read_magazine");
		}
		
		private function flush():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bathroom_toilet_flush_01.mp3",1);
			SceneUtil.lockInput(this);
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,flushing));
			addSystem(new EarthquakeSystem());
			var cameraShake:Entity = EntityUtils.createSpatialEntity(this,new MovieClip(), _hitContainer);
			cameraShake.add(new Earthquake(player.get(Spatial),new Point(0,25),.5,50)).add(new Id("cameraShake"));
			SceneUtil.setCameraTarget(this, cameraShake);
		}
		
		private function flushing():void
		{
			SceneUtil.setCameraTarget(this, player);
			removeEntity(getEntityById("cameraShake"));
			Dialog(player.get(Dialog)).complete.addOnce(finishComentary);
			
			if(shellApi.checkEvent(shrink.THUMB_DIRVE_IN_TOILET) && !shellApi.checkEvent(shrink.FLUSHED_THUMB_DRIVE))
			{
				SceneUtil.setCameraTarget(this, villain);
				Dialog(villain.get(Dialog)).sayById("thumb_drive_flushed");
				Dialog(villain.get(Dialog)).complete.addOnce(curses);
				TweenUtils.entityTo(getEntityById("villainShadow"),Spatial,1,{x:3100});
				shellApi.completeEvent(shrink.FLUSHED_THUMB_DRIVE);
			}
			else
				Dialog(player.get(Dialog)).sayById("overdue");
		}
		
		private function curses(...args):void
		{
			SceneUtil.setCameraTarget(this, player);
			Dialog(player.get(Dialog)).sayById("thumb_drive_flushed_2");
		}
		
		private function finishComentary(...args):void
		{
			SceneUtil.lockInput(this, false);
		}		
		
		private function setUpTub():void
		{
			//water
			var waterClip:MovieClip = new MovieClip();
			waterClip.mouseEnabled = false;
			_hitContainer.addChild(waterClip);
			tubWater = getEntityById("water");
			EntityUtils.visible( tubWater, true );
			var disp:Display = tubWater.get(Display);
			disp.isStatic = false;
			disp.setContainer(waterClip);
			tubWater.remove(Sleep);
			
			var clip:MovieClip = _hitContainer["bubbles_mc"];
			BitmapUtils.convertContainer(disp.displayObject);
			var waterBubbles:Entity = EntityUtils.createSpatialEntity(this, clip,waterClip);
			var follow:FollowTarget = new FollowTarget(tubWater.get(Spatial));
			waterBubbles.add(new Id("waterBubbles")).add(follow);
			TimelineUtils.convertClip(clip, this, waterBubbles);
			
			waterClip.mask = _hitContainer["tubMask"];
			BitmapUtils.convertContainer(waterClip);
			
			tubWater.add(new SoapyWater(waterBubbles.get(Spatial),TUB_FILLED_HEIGHT, TUB_EMPTY_HEIGHT, 10, 20, shellApi.checkEvent(shrink.FAUCET_ON)));
			
			//faucet
			clip = _hitContainer["faucet_mc"];
			var faucet:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip, this,faucet,null,shellApi.checkEvent(shrink.FAUCET_ON));
			faucet.add(new Id("faucetWater"));
			var time:Timeline =	faucet.get(Timeline);
			time.handleLabel("loopFlow",waterFlowing,false);
			time.handleLabel("ending",stopWaterFlow,false);
			var audio:Audio = new Audio();
			faucet.add(audio).add(new AudioRange(1000, 0, 1, Quad.easeOut));
			
			
			//duck
			var duck:Entity = setUpFloatingAssets("duck", DUCK_DENSITY, tubWater);
			
			follow = new FollowTarget(duck.get(Spatial));
			follow.offset = new Point(75, -210);
			
			clip = _hitContainer["duckWall"];
			var duckWall:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			duckWall.add(new Wall()).add(follow);
			Display(duckWall.get(Display)).alpha = 0;
			
			//soap
			var soap:Entity = setUpFloatingAssets("soap", DUCK_DENSITY * 2, tubWater);
			
			var sceneObjectMotion:SceneObjectMotion = new SceneObjectMotion();
			sceneObjectMotion.rotateByPlatform = false;
			sceneObjectMotion.rotateByVelocity = false;
			sceneObjectMotion.platformFriction = 500;
			
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = TUB_FILLED_HEIGHT;
			threshold.entered.add(soapInWater);
			
			soap.add(sceneObjectMotion).add(new RectangularCollider()).add(new Mass(100))
				.add(new SceneCollider()).add(new MotionBounds(new Rectangle(2330, 400, 600, 750)))
				.add(new SceneObjectHit( true, true )).add(new WallCollider()).add(threshold);
			
			//handle
			var handleCollider:Entity = getEntityById("handleCollider");
			Display(handleCollider.get(Display)).isStatic = false;
			
			clip = _hitContainer["bb1"];
			var handle:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip,this,handle,null,false);
			time = handle.get(Timeline);
			time.handleLabel("loopRight",rotateRight,false);
			time.handleLabel("loopLeft",rotateLeft,false);
			
			handle.add(new WalkToTurnDial(handleCollider,false, false,100,0,.5,0)).add(new Id("handle"))
				.add(new WalkToTurnTimeline(handle.get(WalkToTurnDial),"turnright","turnleft"));
			
			var turnDial:WalkToTurnDial = handle.get(WalkToTurnDial);
			turnDial.dialOff.add(turnOffWater);
			turnDial.dialOn.add(turnOnWater);
			turnDial.on = shellApi.checkEvent(shrink.FAUCET_ON);
			
			var tubSpatial:Spatial = tubWater.get(Spatial);
			
			var bubbleEmitter:Bubbles = new Bubbles();
			bubbleEmitter.init(new Rectangle(- tubSpatial.width / 2, 0, tubSpatial.width),new Point(0, -100),new Point(.5, 2),5,3,10);
			_bubbleEmitter = EmitterCreator.create(this, _hitContainer, bubbleEmitter, 0,0, null, "bubbles", tubSpatial, false).get(Emitter);
			
			if(shellApi.checkEvent(shrink.FAUCET_ON))
			{
				Spatial(duck.get(Spatial)).y = TUB_FILLED_HEIGHT;
				audio.play(TUB_FILL_SOUND,true,SoundModifier.POSITION);
			}
			
			addSystem(new WalkToTurnDialSystem());
			addSystem(new WalkToTurnTimelineSystem());
			addSystem(new WaveMotionSystem());
			addSystem(new ThresholdSystem());
			addSystem(new SoapyWaterSystem());
		}
		
		private var _bubbleEmitter:Emitter;
		private var _soapInWater:Boolean = false;
		
		private function soapInWater():void
		{
			MotionBounds(getEntityById("soapFloatHit").get(MotionBounds)).box.left = 2000;
			_soapInWater = true;
			if(shellApi.checkEvent(shrink.FAUCET_ON))
			{
				_bubbleEmitter.start = true;
				_bubbleEmitter.emitter.counter.resume();
			}
		}
		
		private function setUpFloatingAssets(id:String, density:Number, water:Entity):Entity
		{
			var platHit:String = "PlatHit";
			var floatHit:String = "FloatHit";
			
			// FLOATING COLLIDER
			var clip:MovieClip = _hitContainer[id+floatHit];
			var float:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
			
			var waterCollider:WaterCollider = new WaterCollider();
			waterCollider.density = density;          
			waterCollider.dampener = BUOYANCY_DAMPENER;
			
			var edge:Edge = new Edge();
			edge.unscaled = clip.getBounds(clip);
			
			float.add(new Id(clip.name)).add( waterCollider ).add( new SceneObjectCollider())
				.add(new BitmapCollider()).add(edge).add(new PlatformCollider()).add(new CurrentHit());
			
			Display(float.get(Display)).alpha = 0;
			
			// PLATFORM
			var plat:Entity = getEntityById(id+platHit);
			Display(plat.get(Display)).isStatic = false;
			
			var differenceY:Number = plat.get(Spatial).y - float.get(Spatial).y;
			var follow:FollowTarget = new FollowTarget(float.get(Spatial));
			follow.offset = new Point(0, differenceY);
			
			plat.add(follow);
			
			// DISPLAY
			clip = _hitContainer[id];
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);	
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "rotation";
			waveMotionData.magnitude = 2;
			waveMotionData.rate = .05;
			waveMotionData.radians = 0;
			
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.data.push( waveMotionData );
			
			differenceY = entity.get(Spatial).y - float.get(Spatial).y;
			follow = new FollowTarget(float.get(Spatial));
			follow.offset = new Point(0, differenceY);
			
			entity.add(new Id(clip.name)).add(follow).add(new SpatialAddition()).add( waveMotion );
			
			float.remove(Sleep);
			
			return float;
		}
		
		private const TUB_FILL_SOUND:String = SoundManager.EFFECTS_PATH+"bathtub_fill_01_loop.mp3";
		private const TUB_DRAIN_SOUND:String = SoundManager.EFFECTS_PATH+"bathtub_drain_01_loop.mp3";
		
		private function turnOnWater():void
		{
			var water:Entity = getEntityById("faucetWater");
			Timeline(water.get(Timeline)).gotoAndPlay(0);
			
			var audio:Audio = water.get(Audio);
			audio.play(TUB_FILL_SOUND, true, SoundModifier.POSITION);
			audio.stop(TUB_DRAIN_SOUND, SoundType.EFFECTS);
			
			shellApi.completeEvent(shrink.FAUCET_ON);
			
			SoapyWater(tubWater.get(SoapyWater)).filling = true;
			
			if(_soapInWater)
				soapInWater();
			if(_soapInWater)
				soapInWater();
		}
		
		private function turnOffWater():void
		{
			var water:Entity = getEntityById("faucetWater");
			Timeline(water.get(Timeline)).gotoAndPlay("done");
			
			var audio:Audio = water.get(Audio);
			audio.stop(TUB_FILL_SOUND, SoundType.EFFECTS);
			audio.play(TUB_DRAIN_SOUND,true,SoundModifier.POSITION);
			
			shellApi.removeEvent(shrink.FAUCET_ON);
			SoapyWater(tubWater.get(SoapyWater)).filling = false;
		}
		
		private function stopBubbles():void
		{
			AudioUtils.stop(this, TUB_DRAIN_SOUND);
			_bubbleEmitter.emitter.counter.stop();
		}
		
		private function rotateLeft():void
		{
			Timeline(getEntityById("handle").get(Timeline)).gotoAndStop("turnleft");
		}
		
		private function rotateRight():void
		{
			Timeline(getEntityById("handle").get(Timeline)).gotoAndStop("turnright");
		}
		
		private function stopWaterFlow():void
		{
			Timeline(getEntityById("faucetWater").get(Timeline)).gotoAndStop(0);
		}
		
		private function waterFlowing():void
		{
			Timeline(getEntityById("faucetWater").get(Timeline)).gotoAndPlay("flow");
		}
	}
}