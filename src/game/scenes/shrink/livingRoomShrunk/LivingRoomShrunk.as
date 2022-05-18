package game.scenes.shrink.livingRoomShrunk
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.Hazard;
	import game.components.hit.HitTest;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.Water;
	import game.components.hit.Zone;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.TargetEntity;
	import game.components.motion.Threshold;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Place;
	import game.data.item.UseItemData;
	import game.scene.template.ItemGroup;
	import game.scenes.shrink.livingRoomShrunk.FishSystem.Fish;
	import game.scenes.shrink.livingRoomShrunk.FishSystem.FishSystem;
	import game.scenes.shrink.livingRoomShrunk.Particles.Bubbles;
	import game.scenes.shrink.livingRoomShrunk.Particles.FishFood;
	import game.scenes.shrink.livingRoomShrunk.Particles.StaticElectricity;
	import game.scenes.shrink.livingRoomShrunk.StaticSystem.Static;
	import game.scenes.shrink.livingRoomShrunk.StaticSystem.StaticBalloon;
	import game.scenes.shrink.livingRoomShrunk.StaticSystem.StaticBalloonSystem;
	import game.scenes.shrink.livingRoomShrunk.StaticSystem.StaticClimbSystem;
	import game.scenes.shrink.livingRoomShrunk.StaticSystem.StaticSystem;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.shrink.shared.Systems.PressSystem.Press;
	import game.scenes.shrink.shared.Systems.PressSystem.PressSystem;
	import game.scenes.shrink.shared.groups.CarGroup;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class LivingRoomShrunk extends ShrinkScene
	{
		public function LivingRoomShrunk()
		{
			//showHits = true;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/livingRoomShrunk/";
			
			super.init(container);
		}
		
		private var filterOn:Mover;
		private var filterOff:Mover;
		private var waterDensity:Number = .8;
		private var targetEntity:TargetEntity;
		private var catHazard:Hazard;
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			addSystem(new SceneObjectHitRectSystem());
			addSystem(new SceneObjectMotionSystem());
			addSystem(new ZoneHitSystem(),SystemPriorities.checkCollisions);
			addSystem(new StaticSystem());
			addSystem(new StaticClimbSystem());
			addSystem(new HitTestSystem());
			addSystem(new ThresholdSystem());
			addSystem( new HitTheDeckSystem());
			
			addSystem(new PressSystem());
			addSystem(new StaticBalloonSystem());
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setUpPlayer();
			setUpRemote();
			setUpTank();
			setUpTV();
			setUpCat();
			setUpBalloons();
		}
		
		private function setUpBalloons():void
		{
			for(var i:int = 1; i <= 3; i++)
			{
				var clip:MovieClip = _hitContainer[ "balloon" + i ];
				BitmapUtils.convertContainer(clip);
				var balloon:Entity = EntityUtils.createMovingEntity(this,clip,_hitContainer);
				balloon.add(new Static(balloon,0,2,5,true)).add(new HitTheDeck(player.get(Spatial),clip.width / 2,false)).add(new StaticBalloon(new Point(clip.x, clip.y))).add(new Id(clip.name));
				HitTheDeck(balloon.get(HitTheDeck)).duck.add(hitBalloon);
				var motion:Motion = balloon.get(Motion);
				motion.friction = new Point(235,235);
				DisplayUtils.moveToOverUnder( clip, _hitContainer[ "antennae" ]);
			}
		}
		
		private function hitBalloon( balloon:Entity ):void
		{
			if( StaticBalloon( balloon.get( StaticBalloon )).returning )
				return;
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "balloon_bounce_0" + GeomUtils.randomInt( 1, 2 )+".mp3" );
			
			var motion:Motion = balloon.get(Motion);
			var playerMotion:Motion = player.get(Motion);
			
			motion.velocity = new Point(playerMotion.velocity.x, playerMotion.velocity.y);
			
			var static:Static = player.get(Static);
			
			StaticBalloon(balloon.get(StaticBalloon)).hitBalloon(static);
			
			if(static.charged)
			{
				var follow:FollowTarget = new FollowTarget(balloon.get(Spatial));
				follow.offset = new Point(playerMotion.x - motion.x + motion.velocity.x * .01, playerMotion.y - motion.y + motion.velocity.y * .01);
				player.add(follow);
				playerMotion.pause = true;
			}
		}
		
		private function setUpPlayer():void
		{
			player.add(new Static(player, .5));
			var static:Static = player.get(Static);
			static.fullyCharged.add(playerCharged);
			static.discharged.add(playerDischarged);
			
			var scale:Number = player.get(Spatial).scale;
			
			var clip:MovieClip = EntityUtils.getDisplayObject(player) as MovieClip;
			var rect:Rectangle = clip.getRect(clip);
			rect = new Rectangle(rect.x * scale, rect.y * scale, rect.width * scale, rect.height *scale);
			
			var sparks:StaticElectricity = new StaticElectricity(rect,15,5,15,.5,10);
			var entity:Entity = EmitterCreator.create(this,_hitContainer,sparks,0,0,null,"playerElectricity",player.get(Spatial),false);
		}
		
		private function playerDischarged(...args):void
		{
			var emitter:Emitter = getEntityById("playerElectricity").get(Emitter);
			emitter.emitter.counter.stop();
			player.remove(FollowTarget);
			Motion(player.get(Motion)).pause = false;
		}
		
		private function playerCharged(...args):void
		{
			var emitter:Emitter = getEntityById("playerElectricity").get(Emitter);
			emitter.emitter.counter.resume();
			emitter.start = true;
		}
		
		private function setUpCat():void
		{
			var cat:Entity = getEntityById("cat");
			var clip:MovieClip = EntityUtils.getDisplayObject(cat) as MovieClip;
			BitmapUtils.convertContainer(clip);
			TimelineUtils.convertClip(clip,this,cat,null,false);
			Timeline(cat.get(Timeline)).handleLabel("ending",stopCatFight,false);
			DisplayUtils.moveToBack(clip);
			var catPos:Spatial = cat.get(Spatial);
			catPos.x = 465;
			catPos.y = 1700;
			
			catHazard = getEntityById("catHit").get(Hazard);
			getEntityById("catHit").remove(Hazard);
			
			var zone:Entity = getEntityById("catZone");
			Display(zone.get(Display)).alpha = 0;
			Zone(zone.get(Zone)).inside.add(catFight);
		}
		
		private function stopCatFight(...args):void
		{
			getEntityById("catHit").remove(Hazard);
			var cat:Entity = getEntityById("cat");
			Timeline(cat.get(Timeline)).gotoAndStop(0);
		}
		
		private function catFight(...args):void
		{
			if(shellApi.checkEvent(shrink.IN_CAR))
				return;
			getEntityById("catHit").add(catHazard);
			var cat:Entity = getEntityById("cat");
			Timeline(cat.get(Timeline)).play();
		}
		
		private function setUpTV():void
		{
			var clip:MovieClip = _hitContainer["tvGlow"];
			BitmapUtils.convertContainer(clip);
			var entity:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			TimelineUtils.convertClip(clip,this,entity,null,false);
			entity.add(new Id("tvGlow"));
			
			if(shellApi.checkEvent(shrink.TV_ON))
				Timeline(entity.get(Timeline)).play();
			else
				Display(entity.get(Display)).visible = false;
			DisplayUtils.moveToBack(clip);
			
			setUpSparks();
			
			var hit:HitTest;
			
			for(var i:int = 1; i <= 2; i++)
			{
				hit = new HitTest(jumpOnAntenna, false, jumpOffAntenna);
				var antenna:Entity = getEntityById("climbAntenna"+i);
				antenna.add(new Static(antenna,0,3,0,false)).add(hit);
				
				if(shellApi.checkEvent(shrink.TV_ON))
					Static(antenna.get(Static)).transferPriority = 1;
			}
		}
		
		private function jumpOffAntenna(...args):void
		{
			Display(player.get(Display)).moveToFront();
		}
		
		private function jumpOnAntenna(...args):void
		{
			Display(player.get(Display)).moveToBack();
		}		
		
		private function setUpSparks():void
		{
			var antenna:MovieClip = _hitContainer["antennae"];
			var sparks:StaticElectricity = new StaticElectricity(antenna.getRect(_hitContainer),21,7,15,.5,10);
			var entity:Entity = EmitterCreator.create(this,_hitContainer,sparks,0,0,null,"staticElectricty",null,shellApi.checkEvent(shrink.TV_ON));
			trace(entity.get(Id).id);
		}
		
		private function setUpTank():void
		{
			var water:Entity = getEntityById("fishTankWater");
			filterOn = water.get(Mover);
			
			filterOff = new Mover();
			filterOff.stickToPlatforms = false;
			
			setUpBubbles();
			setUpFilterButtons();
			setUpFish();
			setUpFishFood();
			setUpKey();
			
			Display( getEntityById( "swimZone" ).get( Display )).alpha = .5;
		}
		
		private function setUpKey():void
		{
			var clip:MovieClip = _hitContainer[ "diaryKey" ];
			
			if( shellApi.checkHasItem( shrink.DIARY_KEY ))
			{	
				_hitContainer.removeChild( clip );
			}
			else
			{
				BitmapUtils.convertContainer( clip );
				
				var key:Entity = EntityUtils.createSpatialEntity( this, clip );
				key.add( new HitTheDeck( player.get( Spatial ), 50 )).add( new Id( "diaryKey" ));
				HitTheDeck( key.get( HitTheDeck )).duck.add( pickUpKey );
			}
		}
		
		private function pickUpKey(key:Entity):void
		{
			removeEntity(key);
			shellApi.getItem(shrink.DIARY_KEY,null,true);
		}
		
		private function setUpFishFood():void
		{
			var clip:MovieClip = _hitContainer["fishFood"];
			BitmapUtils.convertContainer(clip);
			var entity:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			entity.remove(Sleep);
			TimelineUtils.convertClip(clip,this,entity,null,false);
			var time:Timeline = entity.get(Timeline);
			time.handleLabel("ending", Command.create(stopTipping,time),false);
			time.handleLabel("tip",spillFood,false);
			
			var threshold:Threshold = new Threshold("x", "<");
			threshold.threshold = 1330;
			threshold.entered.add(Command.create(tipFood, entity));
				
			var creator:SceneObjectCreator = new SceneObjectCreator();
			clip = _hitContainer["fishFoodHit"];
			var hit:Entity = creator.createBox(clip, 0, _hitContainer, NaN, NaN,null, null, new Rectangle(1265, 650, 380, 80), this, null, null, 200);
			hit.add(new Id(clip.name)).add(new PlatformCollider()).add(threshold).remove(Sleep);
			var follow:FollowTarget = new FollowTarget(hit.get(Spatial));
			follow.offset = new Point(0, clip.height / 2);
			entity.add(follow);
			Display(hit.get(Display)).alpha = 0;
			
			clip = _hitContainer["fishBits"];
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( _hitContainer[ "pellet" ]);
			var foodPart:FishFood = new FishFood();
			foodPart.init( bitmapData, new Point(-250, -250));
			
			var fishFood:Entity = EmitterCreator.create(this,_hitContainer,foodPart,clip.x,clip.y,null,"fishBits",null,false);
			fishFood.remove(Sleep);
		}
		
		private function tipFood(food:Entity):void
		{
			Timeline( food.get( Timeline )).play();
		}
		
		private function spillFood():void
		{
			var emitter:Emitter = getEntityById("fishBits").get(Emitter);
			emitter.start = true;
			emitter.emitter.counter.resume();
			feast();
		}
		
		private function stopTipping(timeline:Timeline):void
		{
			var fishFoodHit:Entity = getEntityById("fishFoodHit");
			var hitSpatial:Spatial = fishFoodHit.get(Spatial);
			var threshold:Threshold = fishFoodHit.get(Threshold);
			
			hitSpatial.x = threshold.threshold;
			
			timeline.gotoAndStop(0);
			
			var emitter:Emitter = getEntityById("fishBits").get(Emitter);
			emitter.emitter.counter.stop();
		}
		
		private function setUpFish():void
		{
			addSystem(new FishSystem());
			
			var fishFood:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["floatingFood"],_hitContainer);
			fishFood.add(new Id("floatingFood")).remove(Sleep);
			Display(fishFood.get(Display)).visible = false;
			
			var tankZone:Entity = getEntityById("swimZone");
			Zone(tankZone.get(Zone)).entered.add(kaplunk);
			var tank:MovieClip = EntityUtils.getDisplayObject(tankZone) as MovieClip;
			
			for(var i:int = 1; i <=3; i++)
			{
				var fishName:String = "fish"+i;
				var clip:MovieClip = _hitContainer[fishName];
				BitmapUtils.convertContainer(clip);
				var fish:Entity = EntityUtils.createMovingEntity(this,clip,_hitContainer);
				TimelineUtils.convertClip(clip,this,fish);
				Timeline(fish.get(Timeline)).labelReached.add(Command.create(handelFishTimelines, fish.get(Timeline)));
				fish.add(new Fish(tank.getRect(_hitContainer),tankZone.get(Zone),300)).add(new Id(fishName));
				
				clip = _hitContainer[fishName+"Hit"];
				var collider:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				Display(collider.get(Display)).alpha = 0;
				var hazard:Hazard = new Hazard();
				hazard.velocity = new Point(0,1000);
				hazard.coolDown = .1;
				hazard.interval = 1;
				collider.add(hazard).add(new Id(fishName+"Hit")).add(new FollowTarget(fish.get(Spatial)));
			}
		}
		
		private function kaplunk(...args):void
		{
			if(Motion(player.get(Motion)).velocity.y > 0 )
				Motion(player.get(Motion)).velocity.y = 0;
		}
		
		private function feast():void
		{
			var fishFood:Entity = getEntityById( "floatingFood" );
			Display( fishFood.get( Display )).visible = true;
			var key:Entity = getEntityById( "diaryKey" );
			if( key != null )
			{
				HitTheDeck( key.get( HitTheDeck )).ignoreProjectile = false;
			}
			for( var i:int = 1; i <=3; i ++ )
			{
				var fish:Entity = getEntityById( "fish" + i );
				Fish( fish.get( Fish )).feast( fishFood.get( Spatial ));
				removeEntity( getEntityById( "fish" + i + "Hit" ));
			}
		}
		
		private function handelFishTimelines( label:String, timeline:Timeline ):void
		{
			var startLabels:Array = ["idle", "angry", "feeding"];
			var end:String = "end_";
			for(var i:int = 0; i < startLabels.length; i++)
			{
				var start:String = startLabels[i];
				if(label == end+start)
				{
					timeline.gotoAndPlay(start);
					return;
				}
			}
		}
		
		private function setUpBubbles():void
		{
			var bubbles:Bubbles = new Bubbles();
			var clip:MovieClip = _hitContainer["bubbles"];
			clip.visible = false;
			bubbles.init(clip.getRect(_hitContainer),new Point(0,-25),new Point(2,4),10,.33,2,1,-25);
			var entity:Entity = EmitterCreator.create(this,_hitContainer,bubbles,0,0,null,"bubbles");
			
			bubbles = new Bubbles();
			clip = _hitContainer["bubbles2"];
			clip.visible = false;
			bubbles.init(clip.getRect(_hitContainer),new Point(-50,-50),new Point(2,4),5,.5,2,1,-50);
			entity = EmitterCreator.create(this,_hitContainer,bubbles,0,0,null,"bubbles2");
		}
		
		private function setUpFilterButtons():void
		{
			var clip:MovieClip = _hitContainer[ "filter" ];
			var filterSequence:BitmapSequence = BitmapTimelineCreator.createSequence( clip, true );
			
			var entity:Entity = BitmapTimelineCreator.createBitmapTimeline( clip, true, true, filterSequence );
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndStop( "on" );
			timeline.labelReached.add( toggleFilter );
				
			addEntity( entity );
			entity.add( new Id( "filter" ));
			
			var interaction:Interaction = InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			interaction.click.add( toggleFilterSwitch );
			ToolTipCreator.addToEntity(entity);
			Display( entity.get( Display )).moveToBack();
		}
		
		
		private function toggleFilterSwitch( filter:Entity ):void
		{
			var timeline:Timeline = filter.get( Timeline );
			timeline.play();
			
		}
		
		private function toggleFilter( label:String ):void
		{
			var bubble1:Emitter = getEntityById( "bubbles" ).get( Emitter );
			var bubble2:Emitter = getEntityById( "bubbles2" ).get( Emitter );
			var key:Entity = getEntityById( "diaryKey" );
			var water:Entity = getEntityById( "fishTankWater" );			
			
			if( label == "on" )
			{
				water.add( filterOn );
				Water( water.get( Water )).density = 1;
				bubble1.start = true;
				bubble1.emitter.counter.resume();
				bubble2.start = true;
				bubble2.emitter.counter.resume();
				
				if( key )
				{
					ToolTipCreator.removeFromEntity( key );
				}
			}
			else if( label == "off" )
			{
				water.add( filterOff );
				Water( water.get( Water )).density = waterDensity;
				bubble1.emitter.counter.stop();
				bubble2.emitter.counter.stop();
				
				if( key )
				{
					ToolTipCreator.addToEntity( key );
				}
			}
		}
		
		private function setUpRemote():void
		{
			var clip:MovieClip = _hitContainer["tvRemote"];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip );
			}
			
			clip[ "hatch" ].mouseEnabled = false;
			clip[ "hatch" ].mouseChildren = false;
			
			var interactionNames:Array = ["battery","powerBtn"];
			var interactionFunctions:Array = [clickBattery,clickPowerButton];
			
			setUpParentedClip(clip,interactionNames,interactionFunctions);
			
			if(!shellApi.checkEvent(shrink.REMOTE_HAS_BATTERY))
			{
				Display(getEntityById("tvRemote_battery").get(Display)).visible = false;
			}
			
			var platform:Entity = getEntityById("tvRemote_platformBtn");
			var button:Entity = getEntityById("tvRemote_powerBtn");
			var press:Press = new Press( new Point( 1490, 1500 ), platform );
			press.pressed.add(pressButton);
			Display( platform.get( Display )).alpha = 0;
			button.add( press ).add(new Motion());
		}
		
		private function pressButton(entity:Entity):void
		{
			shellApi.triggerEvent("press_remote");
			var press:Press = entity.get(Press);
			if(!shellApi.checkEvent(shrink.REMOTE_HAS_BATTERY))
				Dialog(player.get(Dialog)).sayById(shrink.NEEDS + shrink.BATTERY);
			else
				turnOnTV();
		}
		
		private function turnOnTV():void
		{
			if(shellApi.checkEvent(shrink.TV_ON))
				return;
			shellApi.triggerEvent(shrink.TV_ON, true);
			
			var entity:Entity = getEntityById("staticElectricty");
			
			var emitter:Emitter = entity.get(Emitter);
			emitter.emitter.counter.resume();
			emitter.start = true;
			
			var glow:Entity = getEntityById("tvGlow");
			Timeline(glow.get(Timeline)).play();
			Display(glow.get(Display)).visible = true;
			
			for(var i:int = 1; i <= 2; i++)
			{
				var antenna:Entity = getEntityById("climbAntenna"+i);
				Static(antenna.get(Static)).transferPriority = 1;
			}
			
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this,glow);
			SceneUtil.addTimedEvent(this,new TimedEvent(2,1,returnToGame));
		}
		
		private function returnToGame():void
		{
			FSMControl(player.get(FSMControl)).active = true;
			SceneUtil.lockInput(this,false);
			SceneUtil.setCameraTarget(this,player);
		}
		
		private function setUpParentedClip(clip:MovieClip,interactionNames:Array= null,interactionFunctions:Array = null,followParent:Boolean = false):void
		{
			var parentEntity:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			parentEntity.add(new Id(clip.name));
			var children:int = clip.numChildren;
			for(var i:int = 0; i < children; i++)
			{
				var child:MovieClip = clip.getChildAt(clip.numChildren - 1) as MovieClip;
				var entity:Entity = EntityUtils.createSpatialEntity(this,child,_hitContainer);
				entity.add(new Id(clip.name + "_" + child.name));
				Display(entity.get(Display)).moveToBack();
				
				if(followParent)
				{
					var follow:FollowTarget = new FollowTarget(parentEntity.get(Spatial));
					follow.offset = new Point(child.x, child.y);
					entity.add(follow);
				}
				else
				{
					var pos:Spatial = entity.get(Spatial);
					pos.x += clip.x;
					pos.y += clip.y;
				}
				
				if(child.name.substr(0,8) == "platform")
				{
					entity.add(new Platform());
					//Display(entity.get(Display)).alpha = 0;
				}
				
				if(interactionNames == null)
					continue;
				
				var index:int = interactionNames.indexOf(child.name);
				if(index != -1)
				{
					var interaction:Interaction = InteractionCreator.addToEntity(entity,["click"],child);
					interaction.click.add(interactionFunctions[index]);
					ToolTipCreator.addToEntity(entity);
				}
			}
		}
		
		private function clickPowerButton(button:Entity):void
		{
			targetEntity = player.get(TargetEntity);
			player.remove(TargetEntity);
			CharUtils.moveToTarget(player,button.get(Spatial).x, button.get(Spatial).y - 125,false,comment);
		}
		
		private function comment(player:Entity):void
		{
			player.add(targetEntity);
		}
		
		override public function setUpCar():void
		{
			useableItems[shrink.BATTERY] = new UseItemData(useBattery, true);
			var startPos:Point = new Point(2700, 1700);
			carGroup = addChildGroup(new CarGroup(_hitContainer, this, startPos)) as CarGroup;
		}
		
		override public function useBattery():void
		{
			var carBattery:Entity = getEntityById("car_battery");
			var remoteBattery:Entity = getEntityById("tvRemote_battery");
			var car:Entity = getEntityById("car");
			var carSpatial:Spatial;
			if(car != null)
				carSpatial = getEntityById("car").get(Spatial);
			if(shouldUseItem(carBattery, carSpatial) && shouldUseItem(remoteBattery))
			{
				var cbSpatial:Spatial = carBattery.get(Spatial);
				var rbSpatial:Spatial = remoteBattery.get(Spatial);
				var pSpatial:Spatial = player.get(Spatial);
				
				var playerPos:Point = new Point(pSpatial.x, pSpatial.y);
				
				var cbDistance:Number = Point.distance(new Point(cbSpatial.x + carSpatial.x, cbSpatial.y + carSpatial.y),playerPos);
				
				var rbDistance:Number = Point.distance(new Point(rbSpatial.x,rbSpatial.y), playerPos);
				
				if(cbDistance < rbDistance)
					moveToTarget(car, Command.create(putBatteryInCar,carBattery));
				else
					moveToTarget(remoteBattery, Command.create(putBatteryInRemote,remoteBattery));
			}
			else
			{
				if(shouldUseItem(remoteBattery))
					moveToTarget(remoteBattery, Command.create(putBatteryInRemote,remoteBattery));
				else
				{
					if(shouldUseItem(carBattery, carSpatial))
						moveToTarget(car, Command.create(putBatteryInCar,carBattery));
					else
						Dialog(player.get(Dialog)).sayById(shrink.NO_POINT + shrink.BATTERY);
				}
			}
		}
		
		private function moveToTarget(entity:Entity, onComplete:Function = null):void
		{
			var spatial:Spatial = entity.get(Spatial);
			var destination:Destination = CharUtils.moveToTarget(player, spatial.x, spatial.y, false, onComplete);
			destination.ignorePlatformTarget = true;
			destination.validCharStates = new <String>[CharacterState.STAND];
		}
		
		private function putBatteryInRemote(player:Entity, battery:Entity):void
		{
			usedBattery(battery);
			shellApi.completeEvent(shrink.REMOTE_HAS_BATTERY);
		}
		
		private function putBatteryInCar(player:Entity, battery:Entity):void
		{
			CharUtils.setDirection(player, true);
			usedBattery(battery);
			var hatch:Entity = getEntityById("car_hatch");
			shellApi.completeEvent(shrink.CAR_HAS_BATTERY);
			TweenUtils.entityTo(hatch,Spatial,1,{rotation:0});
		}
		
		private function usedBattery(battery:Entity):void
		{
			shellApi.triggerEvent("place_battery");
			Display(battery.get(Display)).visible = true;
			shellApi.removeItem(shrink.BATTERY);
			CharUtils.setAnim(player, Place);
			Timeline(player.get(Timeline)).handleLabel("ending", returnToGame);
		}
		
		private function shouldUseItem(target:Entity, parent:Spatial = null):Boolean
		{
			if(target == null)
				return false;
			
			var checkDistance:Number = 300;
			var playerPos:Point = new Point(player.get(Spatial).x, player.get(Spatial).y);
			var targetPos:Point = new Point(target.get(Spatial).x, target.get(Spatial).y);
			
			if(parent != null)
			{
				targetPos.x += parent.x;
				targetPos.y += parent.y;
			}
			
			var distance:Number = Point.distance(playerPos,targetPos);
			
			if(distance < checkDistance)
				return true;
			
			return false;
		}
		
		private function clickBattery(battery:Entity):void
		{
			Display(battery.get(Display)).visible = false;
			ItemGroup(getGroupById(ItemGroup.GROUP_ID)).showAndGetItem(shrink.BATTERY);
			shellApi.removeEvent(shrink.REMOTE_HAS_BATTERY);
		}
	}
}