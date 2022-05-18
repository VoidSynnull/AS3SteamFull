package game.scenes.shrink.bathroomShrunk01
{
	import com.greensock.easing.Quad;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.Ceiling;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.SeeSaw;
	import game.components.hit.Zone;
	import game.components.motion.DirectionalMover;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.TargetSpatial;
	import game.components.render.DynamicWire;
	import game.components.render.LightOverlay;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.display.BitmapWrapper;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.scenes.shrink.bathroomShrunk02.BathroomShrunk02;
	import game.scenes.shrink.kitchenShrunk01.Particles.AirCurrent;
	import game.scenes.shrink.kitchenShrunk01.Particles.Fog;
	import game.scenes.shrink.livingRoomShrunk.Particles.Bubbles;
	import game.scenes.shrink.schoolInterior.SprayEmitter;
	import game.scenes.shrink.shared.Systems.PressSystem.Press;
	import game.scenes.shrink.shared.Systems.PressSystem.PressSystem;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDial;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDialSystem;
	import game.scenes.shrink.shared.Systems.WalkToTurnTimeline.WalkToTurnTimeline;
	import game.scenes.shrink.shared.Systems.WalkToTurnTimeline.WalkToTurnTimelineSystem;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.systems.hit.DirectionalMoverSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MoverHitSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.hit.SeeSawSystem;
	import game.systems.render.DynamicWireSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class BathroomShrunk01 extends ShrinkScene
	{
		public function BathroomShrunk01()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/bathroomShrunk01/";
			
			super.init(container);
		}
		
		private var shadow:Entity;
		private var _sceneObjectCreator:SceneObjectCreator;
		private var _bitmapQuality:Number;
		
		private const WATER_FAUCET_SOUND:String = "water_fountain_large_01_loop.mp3";
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_bitmapQuality = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW ) ? 1 : 3;
			
			_sceneObjectCreator = new SceneObjectCreator();
			
			addSystem(new HitTestSystem());
			addSystem(new PressSystem());
			addSystem(new WalkToTurnDialSystem());
			addSystem(new WalkToTurnTimelineSystem());
			addSystem(new SceneObjectHitRectSystem());
			addSystem(new DynamicWireSystem());
			addSystem(new SeeSawSystem());
			addSystem(new DirectionalMoverSystem());
			addSystem(new MoverHitSystem());
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setUpSpider();
			setUpFaucets();
			setUpFog();
			setUpLights();
			setUpSquirts();
			setUpToothPaste();
			setUpHairDryer();
			setUpShower();
			setUpBrush();
		}
		
		private function setUpBrush():void
		{
			// make the bounce hit not static and follow the brush asset
			var clip:MovieClip = _hitContainer["hairbrushCollision"];
			var collider:Entity = _sceneObjectCreator.createBox(clip, 0, _hitContainer,NaN,NaN,null,null,sceneData.bounds,this,null, null,100,false);
			collider.add(new SceneObjectCollider()).add(new RectangularCollider()).add(new PlatformCollider()).add(new Id("hairBrush"));
			
			var bounceCollision:Entity = getEntityById("hairBrushBounce");
			Display(bounceCollision.get(Display)).isStatic = false;
			var follow:FollowTarget = new FollowTarget(collider.get(Spatial));
			follow.offset = new Point(0, -60);
			bounceCollision.add(follow);
			
			clip = _hitContainer["hairbrush"];
			BitmapUtils.convertContainer(clip);
			var brush:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			brush.add(new FollowTarget(collider.get(Spatial)));
		}
		
		private function setUpShower():void
		{
			var showerZone:Entity = getEntityById("bathroom2Zone");
			Zone(showerZone.get(Zone)).entered.addOnce(fallInShower);
		}
		
		private function fallInShower(...args):void
		{
			shellApi.loadScene(BathroomShrunk02);
		}
		
		private var airCurrent:Entity;
		private function setUpHairDryer():void
		{
			var clip:MovieClip = _hitContainer["hairdryer"];
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip.dryer, null, _bitmapQuality, true, clip );
			
			var interactionNames:Array = [ "red","blue" ];
			var hairDryer:Entity = setUpParentedClip( clip, interactionNames );
			
			var audio:Audio = new Audio();
			audio.currentActions = new Dictionary();
			var data:SoundData = new SoundData(SoundManager.EFFECTS_PATH + "medium_engine_01_loop.mp3", [SoundModifier.POSITION]);
			data.loop = true;
			data.type = "effects";
			audio.currentActions["on"] = data;
			
			hairDryer.add( audio ).add( new Id( clip.name )).add( new AudioRange( 500, 0, 1 ));;
			
			var dryerSpatial:Spatial = hairDryer.get( Spatial );
			var follow:FollowTarget;
			
			player.add( new Mass( 20 ));
			
			// setting up air flow			
			clip = _hitContainer["current"];
			BitmapUtils.convertContainer( clip );
			var current:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			follow = new FollowTarget(dryerSpatial);
			follow.accountForRotation = true;
			follow.properties = new Vector.<String>();
			follow.properties.push("rotation");
			current.add(follow).add(new Mover()).add(new DirectionalMover(0, 0)).add(new Id(clip.name)).add(new EntityIdList());
			
			var air:AirCurrent = new AirCurrent();
			air.init(10, 1, 100, -500, 0);
			
			airCurrent = EmitterCreator.create(this, clip, air, -175, -60, null, null, null, false);
			
			//setting up the wire
			clip = _hitContainer["cordStart"];
			var start:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			
			clip = _hitContainer["cordEnd"];
			var end:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			end.add(new TargetSpatial(start.get(Spatial)));
			end.add(new DynamicWire(500,0x5C574B));
			follow = new FollowTarget(dryerSpatial);
			follow.offset = new Point(clip.x - dryerSpatial.x, clip.y - dryerSpatial.y);
			follow.accountForRotation = true;
			follow.properties = new Vector.<String>();
			follow.properties.push("x", "y", "rotation");
			end.add(follow);
			
			//setting up the platform
			var plat:Entity = getEntityById("dryerPlat");
			clip = EntityUtils.getDisplayObject(plat) as MovieClip;
			Display(plat.get(Display)).isStatic = false;
			follow = new FollowTarget(dryerSpatial);
			follow.offset = new Point(clip.x - dryerSpatial.x, clip.y - dryerSpatial.y);
			follow.accountForRotation = true;
			var edge:Edge = new Edge();
			edge.unscaled = clip.getBounds( clip );
			plat.add( follow ).add( new SeeSaw( 20, 20,-1, 30, hairDryer )).add( edge ).add( new Motion());
		}
	
		private function setUpParentedClip( clip:MovieClip, interactionNames:Array= null ):Entity
		{
			var child:MovieClip;
			var display:Display;
			var entity:Entity;
			var follow:FollowTarget;
			var interaction:Interaction;
			var pos:Spatial;
			var sequence:BitmapSequence;
			var spatial:Spatial;
			var timeline:Timeline;
			
			for( var i:int = 0; i < interactionNames.length; i++ )
			{
				child = clip.getChildByName( interactionNames[ i ]) as MovieClip;
				
				sequence = BitmapTimelineCreator.createSequence( child, this, _bitmapQuality );
				entity = BitmapTimelineCreator.createBitmapTimeline( child, true, true, sequence, _bitmapQuality );
				entity.add( new Id( clip.name + "_" + child.name ));
				this.addEntity( entity );
				
				display = entity.get( Display );
				display.setContainer( _hitContainer );
				display.moveToBack();
				
				spatial = entity.get( Spatial );
				spatial.x = clip.x + child.x;
				spatial.y = clip.y + child.y;
				
				interaction = InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				interaction.click.add( pressDryerBtn );
				ToolTipCreator.addToEntity( entity );
				
			}
			
			var hairDryer:Entity = EntityUtils.createSpatialEntity( this, clip );
			
			for( i = 0; i < interactionNames.length; i++ )
			{
				entity = getEntityById( clip.name + "_" + interactionNames[ i ]);
				spatial = entity.get( Spatial );
				
				follow = new FollowTarget( hairDryer.get( Spatial ));
				follow.offset = new Point( spatial.x - clip.x, spatial.y - clip.y );
				follow.accountForRotation = true;
				follow.properties = new Vector.<String>();
				follow.properties.push("x", "y", "rotation");

				entity.add( follow );
			}
			
			return hairDryer;
		}
		
		private function btnUp(timeline:Timeline):void{timeline.gotoAndStop(0);}
		
		private function btnDown(timeline:Timeline):void{timeline.gotoAndStop(timeline.currentIndex);}
		
		private const DRIER_ACC:Number = 5000;
		
		private function pressDryerBtn( button:Entity ):void//btn:Entity, on:Boolean, btnNumber:int):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "button_02.mp3"  );
			var timeline:Timeline = button.get( Timeline );
			
			timeline.play();
			var mover:DirectionalMover = getEntityById( "current" ).get( DirectionalMover );
			var emitter:Emitter = airCurrent.get(Emitter);
			var dryerAudio:Audio = getEntityById( "hairdryer" ).get( Audio );
			var data:SoundData = dryerAudio.currentActions[ "on" ];
			
			var id:Id = button.get( Id );
			if( id.id == "hairdryer_blue" )
			{
				var otherTimeline:Timeline = getEntityById( "hairdryer_red" ).get( Timeline );
				if( otherTimeline.currentFrameData && otherTimeline.currentFrameData.label == "endDown" )
				{
					otherTimeline.play();
					dryerAudio.stop(data.asset, data.type);
					emitter.emitter.counter.stop();
					mover.acceleration = 0;
				}
			}
			else
			{
				if( timeline.currentFrameData && timeline.currentFrameData.label == "endDown" )
				{
					dryerAudio.stop(data.asset, data.type);
					emitter.emitter.counter.stop();
					mover.acceleration = 0;
				}
				else
				{
					dryerAudio.play(data.asset, data.loop, data.modifiers);
					emitter.start = true;
					emitter.emitter.counter.resume();
					mover.acceleration = DRIER_ACC;
				}
			}
		}
		
		private function setUpToothPaste():void
		{
			var toothPasteHit:Entity = getEntityById("toothpasteSquirt");
			toothPasteHit.add(new HitTest(squirt));
			
			var clip:MovieClip = _hitContainer["toothpaste"];
			BitmapUtils.convertContainer(clip);
			var toothPaste:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			TimelineUtils.convertClip(clip, this,toothPaste, null, false);
			toothPaste.add(new Id("toothPaste"));
			
			var toothPasteSquirt:SprayEmitter = new SprayEmitter(true);
			toothPasteSquirt.init(5, .75 ,-1, 400,800,0x31E8E2,0x10B5B0);
			EmitterCreator.create(this, _hitContainer, toothPasteSquirt, 0, 0, null, "toothPasteSquirt",toothPaste.get(Spatial),false);
		}
		
		private function squirt(...args):void
		{
			Timeline(getEntityById("toothPaste").get(Timeline)).play();
			var emitter:Emitter = getEntityById("toothPasteSquirt").get(Emitter);
			emitter.start = true;
			emitter.emitter.counter.resume();
		}
		
		private function setUpSquirts():void
		{
			var emitters:Vector.<Emitter2D> = new Vector.<Emitter2D>();
			var soapEmitter:SprayEmitter = new SprayEmitter(true);
			soapEmitter.init(1,.6,0,0,1000,0xB4E16A,0x6FA14F);
			emitters.push(soapEmitter);
			
			var hairSprayEmitter:Fog = new Fog();
			hairSprayEmitter.init(25, 10, 5, 2, Math.PI, Math.PI / 3 , 100, 0);
			emitters.push(hairSprayEmitter);
			
			var clip:MovieClip = _hitContainer["bubbleContainer"];
			
			var bubbleEmitter:Bubbles = new Bubbles();
			bubbleEmitter.init(new Rectangle(- 50, 0, 100),new Point(0, -100),new Point(.5, 2),5,3,10);
			EmitterCreator.create(this, clip, bubbleEmitter, 0,0, null, "bubbles", null, false);
			
			var sounds:Array = ["drip_01.mp3", "spray_foam_01_loop.mp3"];
			
			for(var i:int = 0; i < 2; i++)
			{
				var plat:Entity = getEntityById("squirtPlat"+i);
				Display(plat.get(Display)).isStatic = false;
				
				clip = _hitContainer["squirt"+i];
				var squirt:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				
				var limits:Point = new Point(1000, 1025);
				if(i == 1)
					limits = new Point(900,925);
				
				var press:Press = new Press(limits, plat);
				
				var emit:Emitter2D = emitters[i];
				
				var emitter:Entity = EmitterCreator.create(this, _hitContainer[ "bubbleContainer" ], emit, 0, 0, null, "spray"+i, squirt.get(Spatial), false);
				
				press.pressed.add(Command.create(sprayEmitter, emitter.get(Emitter)));
				press.released.add(Command.create(releaseEmitter, emitter.get(Emitter)));
				
				var audio:Audio = new Audio();
				audio.currentActions = new Dictionary();
				var data:SoundData = new SoundData(SoundManager.EFFECTS_PATH + sounds[i]);
				data.loop = (i == 1);
				data.type = "effects";
				audio.currentActions["press"] = data;
				
				squirt.add(press).add(audio).add(new Id(clip.name));
				var pos:Point = new Point(plat.get(Spatial).x, plat.get(Spatial).y);
				
				var follow:FollowTarget = new FollowTarget(squirt.get(Spatial));
				follow.offset = new Point(pos.x - clip.x, pos.y - clip.y);
				plat.add(follow);
			}
		}
		
		private function releaseEmitter(entity:Entity, emitter:Emitter):void
		{
			var audio:Audio = entity.get(Audio);
			var data:SoundData = audio.currentActions["press"];
			audio.stop(data.asset,data.type);
			emitter.emitter.counter.stop();
		}
		private var emits:uint = 0;
		private function sprayEmitter(entity:Entity, emitter:Emitter):void
		{
			var audio:Audio = entity.get(Audio);
			var data:SoundData = audio.currentActions["press"];
			audio.play(data.asset,data.loop);
			emitter.start = true;
			emitter.emitter.counter.resume();
			if(Id(entity.get(Id)).id.indexOf("0") >= 0)// if it is the soap emitter
			{
				emitter = getEntityById("bubbles").get(Emitter);
				SceneUtil.delay(this, .6, Command.create(startBubbles, emitter));
			}
		}
		
		private function startBubbles(bubbles:Emitter):void
		{
			if(!waterOn)
				return;
			bubbles.start = true;
			bubbles.emitter.counter.resume();
			SceneUtil.delay(this, 5, Command.create(stopBubbles, bubbles));
			emits++;
		}
		
		private function stopBubbles(bubbles:Emitter):void
		{
			-- emits;
			if(emits == 0)
				bubbles.emitter.counter.stop();
		}
		
		private function setUpLights():void
		{
			var clip:MovieClip = _hitContainer["shadow"];
			//BitmapUtils.convertContainer(clip);
			shadow = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			
			
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
			
			flipLight();
			
			for(var i:int = 0; i < 2; i++)
			{
				var entity:Entity = getEntityById( "switch" + i );
				entity.add( new Motion());
				Display( entity.get( Display )).alpha = 0;
				Display(entity.get(Display)).isStatic = false;
				EntityUtils.visible(entity, true, true);
			
				Platform( entity.get( Platform )).stickToPlatforms = false;
				var ceiling:Entity = getEntityById( "switchCeiling" + i );
				Display(ceiling.get(Display)).isStatic = false;
				var hit:HitTest = new HitTest(Command.create(flipSwitch, i));
				
				var follow:FollowTarget = new FollowTarget(entity.get(Spatial));
				follow.offset = new Point(0,25);
				ceiling.add(new SceneObjectHit()).add(follow).add(hit);
				
				var press:Press = new Press(new Point(1035,1080),entity);
				var pressed:Boolean = false;
				
				if(i == 0)
				{
					pressed = shellApi.checkEvent(shrink.BATHROOM_LIGHTS_OFF);
					press.pressed.add(pressedLight);
					press.released.add(releasedLight);
				}
				else
				{
					pressed = shellApi.checkEvent(shrink.BATHROOM_VENTS_OFF);
					press.pressed.add(pressedVent);
					press.released.add(releasedVent);
				}
				
				press.setPosition(entity.get(Spatial), pressed, pressed );
				if( !pressed )
				{
					ceiling.remove(Ceiling);
				}
				entity.add(press).add(new Motion());
				
				// ADD VISUAL
				clip = _hitContainer[ "switch" + i + "Vis" ];
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality );
				
				var visualEntity:Entity = EntityUtils.createSpatialEntity( this, clip );
				follow = new FollowTarget( entity.get( Spatial ));
				visualEntity.add( new Id( clip.name )).add( follow );
			}
		}
		
		private function flipSwitch(entity:Entity, hitId:String, switchNumber:int):void
		{
			var motion:Motion = player.get( Motion );
			if( motion.lastVelocity.y < 0)
			{
				var switchEntity:Entity = getEntityById("switch"+switchNumber);
				Press(switchEntity.get(Press)).locked = false;
			}
		}
		
		private function flipLight():void
		{
			var lightOverlay:Entity = getEntityById( "lightOverlay" );
			var display:Display = lightOverlay.get( Display );
			
			display.visible = shellApi.checkEvent( shrink.BATHROOM_LIGHTS_OFF );
		}
		
		private function pressedVent(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			press.locked = true;
			
			shellApi.completeEvent(shrink.BATHROOM_VENTS_OFF);
			getEntityById("switchCeiling1").add(new Ceiling());
			determineFogDisplay();
			Dialog(player.get(Dialog)).sayById("fan_off");
		}
		
		private function releasedVent(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			press.locked = false;
			shellApi.removeEvent(shrink.BATHROOM_VENTS_OFF);
			getEntityById("switchCeiling1").remove(Ceiling);
			determineFogDisplay();
			Dialog(player.get(Dialog)).sayById("fan_on");
		}
		
		private function releasedLight(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			press.locked = false;
			shellApi.removeEvent(shrink.BATHROOM_LIGHTS_OFF);
			flipLight();
			getEntityById("switchCeiling0").remove(Ceiling);
		}
		
		private function pressedLight(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			press.locked = true;
			
			shellApi.completeEvent(shrink.BATHROOM_LIGHTS_OFF);
			flipLight();
			getEntityById("switchCeiling0").add(new Ceiling());
		}
		
		private var hotOn:Boolean = false;
		private var coldOn:Boolean = false;
		private var waterOn:Boolean = false;
		
		private const VENT_SOUND:String = SoundManager.EFFECTS_PATH + "air_ducts_02_loop.mp3";
		
		private function setUpFaucets():void
		{
			var clip:MovieClip = _hitContainer["fountainContainer"];
			BitmapUtils.convertContainer(clip);
			
			if(!shellApi.checkEvent(shrink.BATHROOM_VENTS_OFF))
				AudioUtils.play(this, VENT_SOUND, 1, true);
			
			var faucet:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip, this,faucet);
			faucet.add(new Id("faucetWater")).add(new Audio()).add(new AudioRange(1000, 0,1, Quad.easeOut));
			var time:Timeline =	faucet.get(Timeline);
			time.handleLabel("loopFlow",waterFlowing,false);
			time.handleLabel("ending",stopWaterFlow,false);
			
			var handles:Array = ["hotFaucet", "coldFaucet"];
			for(var i:int = 0; i < 2; i++)
			{
				clip = _hitContainer["faucet"+i];
				BitmapUtils.convertContainer(clip);
				var handle:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				TimelineUtils.convertClip(clip, this,handle);
				time = handle.get(Timeline);
				time.handleLabel("endTurnRight", Command.create(rotateRight, handle),false);
				time.handleLabel("endTurnLeft", Command.create(rotateLeft, handle),false);
				
				var handleCollider:Entity = getEntityById(handles[i]);
				
				handle.add(new WalkToTurnDial(handleCollider,false, false,100,0,1,0))
					.add(new WalkToTurnTimeline(handle.get(WalkToTurnDial),"turnRight","turnLeft"));
				
				var turnDial:WalkToTurnDial = handle.get(WalkToTurnDial);
				turnDial.dialOff.add(Command.create(turnOffWater,handle));
				turnDial.dialOn.add(Command.create(turnOnWater,handle));
			}
		}
		
		private function rotateLeft(handle:Entity):void { Timeline(handle.get(Timeline)).gotoAndStop("turnLeft"); }
		
		private function rotateRight(handle:Entity):void { Timeline(handle.get(Timeline)).gotoAndStop("turnRight"); }
		
		private function stopWaterFlow():void { Timeline(getEntityById("faucetWater").get(Timeline)).gotoAndStop(0); }
		
		private function waterFlowing():void { Timeline(getEntityById("faucetWater").get(Timeline)).gotoAndPlay("flow"); }
		
		private function turnOnWater(handle:Entity):void 
		{ 
			var handleTemp:String = Id(handle.get(Id)).id;
			
			if(handleTemp == "faucet0")
				hotOn = true;
			else
				coldOn = true;
			
			determineFogDisplay();
			
			if(!waterOn)
			{
				var faucet:Entity = getEntityById("faucetWater");
				Timeline(faucet.get(Timeline)).gotoAndPlay(0); 
				Audio(faucet.get(Audio)).play(SoundManager.EFFECTS_PATH + WATER_FAUCET_SOUND,true,SoundModifier.POSITION);
				waterOn = true;
			}
			
			trace("water: " + waterOn + " hot: " + hotOn + " cold: "  + coldOn);
		}
		
		private function turnOffWater(handle:Entity):void 
		{ 
			var handleTemp:String = Id(handle.get(Id)).id;
			if(handleTemp == "faucet0")
				hotOn = false;
			else
				coldOn = false;
			
			determineFogDisplay();
			
			if(waterOn && !hotOn && !coldOn)
			{
				var faucet:Entity = getEntityById("faucetWater");
				Timeline(faucet.get(Timeline)).gotoAndPlay("end"); 
				Audio(faucet.get(Audio)).stop(SoundManager.EFFECTS_PATH + WATER_FAUCET_SOUND,SoundType.EFFECTS);
				waterOn = false;
			}
			
			trace("water: " + waterOn + " hot: " + hotOn + " cold: "  + coldOn);
		}
		
		private function determineFogDisplay():void
		{
			var fogL:Entity = getEntityById("fogL");
			var fogR:Entity = getEntityById("fogR");
			var textL:Entity = getEntityById("textL");
			var textR:Entity = getEntityById("textR");
			
			var emitter:Emitter = _steam.get(Emitter);
			
			if(!shellApi.checkEvent(shrink.BATHROOM_VENTS_OFF))
				AudioUtils.play(this, VENT_SOUND, 1, true);
			else
				AudioUtils.stop(this, VENT_SOUND);
			
			if(hotOn)
			{
				emitter.start = true;
				emitter.emitter.counter.resume();
				TweenUtils.entityTo(fogL, Display, 2, {alpha:1});
				TweenUtils.entityTo(textL, Display, 2, {alpha:1});
				trace(coldOn + " " + shellApi.checkEvent(shrink.BATHROOM_VENTS_OFF));
				if(coldOn || !shellApi.checkEvent(shrink.BATHROOM_VENTS_OFF))
				{
					TweenUtils.entityTo(fogR, Display, 2, {alpha:0});
					TweenUtils.entityTo(textR, Display, 2, {alpha:0});
				}
				else
				{
					TweenUtils.entityTo(fogR, Display, 2, {alpha:1});
					TweenUtils.entityTo(textR, Display, 2, {alpha:1});
				}
			}
			else
			{
				emitter.emitter.counter.stop();
				TweenUtils.entityTo(fogL, Display, 2, {alpha:0});
				TweenUtils.entityTo(textL, Display, 2, {alpha:0});
				TweenUtils.entityTo(fogR, Display, 2, {alpha:0});
				TweenUtils.entityTo(textR, Display, 2, {alpha:0});
			}
		}
		
		private var _steam:Entity;
		private function setUpFog():void
		{
			var messageSides:Array = ["L", "R"];
			var message:MovieClip = _hitContainer["fog"];
			var clip:MovieClip;
			//BitmapUtils.convertContainer(clip);
			//clip.mask= _hitContainer["steamMask"];
			var steam:Fog = new Fog();
			steam.init( 25, 25,200, 1, -Math.PI / 2, Math.PI / 4, 50, -100, new DeathZone( new RectangleZone( -100, -200, 100, 0 ), true ));
			_steam = EmitterCreator.create( this, _hitContainer["steamContainer"], steam, 0, -20,null, null, null, false );
			
			for(var i:int = 0; i < messageSides.length; i++)
			{
				clip = message[ "fog" + messageSides[ i ] ];
				var fog:Entity = EntityUtils.createSpatialEntity(this,clip,message);
				fog.add(new Id(clip.name));
				Display(fog.get(Display)).alpha = 0;
				
				clip = message["diaryText"+messageSides[i]];
				var text:Entity = EntityUtils.createSpatialEntity(this,clip,message);
				text.add(new Id("text"+messageSides[i]));
				Display(text.get(Display)).alpha = 0;
			}
		}
		
		private function setUpSpider():void
		{
			var clip:MovieClip = _hitContainer["spider"];
			BitmapUtils.convertContainer(clip);
			var spider:Entity = EntityUtils.createSpatialEntity(this,clip);
			spider.add( new Id( "spider" )).add( new Tween());
			TimelineUtils.convertAllClips( clip, spider, this );
			
			for each( var child:Entity in spider.get( Children ).children )
			{
				var timeline:Timeline = child.get( Timeline );
				timeline.gotoAndPlay( Math.random() * 19 );
			}
			
			for(var i:int = 0; i < 2; i ++)
			{
				clip = _hitContainer["sphit"+i];
				var hit:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				hit.add(new Id(clip.name));
				var interaction:Interaction = InteractionCreator.addToEntity(hit, ["click"], clip);
				interaction.click.add(Command.create(spookSpider, i));
				ToolTipCreator.addToEntity(hit);
			}
		}
		
		private var scurrying:Boolean = false;
		
		private function spookSpider(start:Entity, spotNumber:int):void
		{
			if(scurrying)
				return;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "insect_scurry_01.mp3");
			
			var leftSpot:Entity = getEntityById("sphit0");
			var rightSpot:Entity = getEntityById("sphit1");
			var leftClip:MovieClip = Display(leftSpot.get(Display)).displayObject as MovieClip;
			var rightClip:MovieClip = Display(rightSpot.get(Display)).displayObject as MovieClip;
			var leftRect:Rectangle = leftClip.getRect(_hitContainer);
			var rightRect:Rectangle = rightClip.getRect(_hitContainer);
			var leftZone:LineZone = new LineZone(leftRect.topLeft, new Point(leftRect.left, leftRect.bottom));
			var rightZone:LineZone = new LineZone(new Point(rightRect.right, rightRect.top), rightRect.bottomRight);
			
			var startPoint:Point;
			var endPoint:Point;
			var spider:Entity = getEntityById("spider");
			var spatial:Spatial = spider.get(Spatial);
			
			if(spotNumber == 0)
			{
				startPoint = leftZone.getLocation();
				endPoint = rightZone.getLocation();
			}
			else
			{
				startPoint = rightZone.getLocation();
				endPoint = leftZone.getLocation();
			}
			spatial.x = startPoint.x;
			spatial.y = startPoint.y;
			spatial.rotation = Math.atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x) * 180 / Math.PI + 180;
			
			TweenUtils.entityTo(spider, Spatial, 1, {x:endPoint.x, y:endPoint.y, onComplete:scurried});
			scurrying = true;
		}
		
		private function scurried():void { scurrying = false; }
	}
}