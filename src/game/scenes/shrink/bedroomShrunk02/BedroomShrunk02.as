package game.scenes.shrink.bedroomShrunk02
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.EntityIdList;
	import game.components.hit.Hazard;
	import game.components.hit.HitTest;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.LabelHandler;
	import game.data.animation.entity.character.PourPitcher;
	import game.data.scene.hit.MovingHitData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.scenes.backlot.extSoundStage2.Swing;
	import game.scenes.backlot.extSoundStage2.SwingSystem;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.bedroomShrunk02.Particles.DustParticle;
	import game.scenes.shrink.bedroomShrunk02.Particles.VentParticle;
	import game.scenes.shrink.bedroomShrunk02.PendulumSystem.Pendulum;
	import game.scenes.shrink.bedroomShrunk02.PendulumSystem.PendulumSystem;
	import game.scenes.shrink.bedroomShrunk02.Popups.MorseCode;
	import game.scenes.shrink.bedroomShrunk02.Popups.TelescopePopup;
	import game.scenes.shrink.bedroomShrunk02.SeaMonkeySystem.SeaMonkey;
	import game.scenes.shrink.bedroomShrunk02.SeaMonkeySystem.SeaMonkeySystem;
	import game.scenes.shrink.bedroomShrunk02.SideFanSystem.SideFan;
	import game.scenes.shrink.bedroomShrunk02.SideFanSystem.SideFanSystem;
	import game.scenes.shrink.bedroomShrunk02.TelescopeSystem.Telescope;
	import game.scenes.shrink.bedroomShrunk02.TelescopeSystem.TelescopeSystem;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.shrink.shared.Systems.PressSystem.Press;
	import game.scenes.shrink.shared.Systems.PressSystem.PressSystem;
	import game.scenes.shrink.shared.Systems.TipSystem.Tip;
	import game.scenes.shrink.shared.Systems.TipSystem.TipSystem;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDial;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDialSystem;
	import game.scenes.shrink.shared.Systems.WeakLiftSystem.WeakLift;
	import game.scenes.shrink.shared.Systems.WeakLiftSystem.WeakLiftSystem;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MoverHitSystem;
	import game.systems.hit.MovingHitSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class BedroomShrunk02 extends ShrinkScene
	{
		
		private var _shrinkEvents:ShrinkEvents;
		private var _bladeHazard:Hazard;
		private var _trashPositions:Vector.<Point>;
		private var _sceneObjectCreator:SceneObjectCreator;
		private var _dustArray:Array;
		private var _topData:BitmapData;
		private var _sideData:BitmapData;
		
		public function BedroomShrunk02()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/bedroomShrunk02/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function destroy():void
		{
			if( _dustArray )
			{
				for (var i:int = 0; i < _dustArray.length; i++) 
				{
					_dustArray[i].dispose();
				}
				_dustArray = null;
			}
			if( _topData ) 	{ _topData.dispose; }
			if( _sideData ) { _sideData.dispose; }

			super.destroy();
		}

		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			addSystem(new MoverHitSystem(), SystemPriorities.move);
			addSystem(new SceneObjectHitRectSystem());
			addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			addSystem(new PressSystem());
			addSystem(new HitTheDeckSystem());
			addSystem(new WalkToTurnDialSystem());
			addSystem(new TelescopeSystem());
			addSystem(new MovingHitSystem());
			addSystem(new WeakLiftSystem());
			addSystem(new HitTestSystem());
			addSystem(new TipSystem());
			addSystem(new SideFanSystem());
			addSystem(new SeaMonkeySystem());
			addSystem(new SwingSystem(player));
			addSystem(new PendulumSystem());
		}
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_shrinkEvents = events as ShrinkEvents;
			
			_sceneObjectCreator = new SceneObjectCreator();
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setUpPendulums();
			setUpSeaMonkies();
			setUpDust();
			setUpFan();
			setUpTrash();
			setUpBalloons();
			setUpPins();
			setUpMorseKey();
			setUpTelescope();
			setUpSchoolNote()
			setUpBall();
			//			setupIslandBlocker();
			
			if(!shellApi.checkEvent(_shrinkEvents.GOT_SHRUNKEN))
			{
				SceneUtil.lockInput(this);
				shellApi.triggerEvent(_shrinkEvents.GOT_SHRUNKEN, true);
			}
		}
		
		//////////////////////////////// ISLAND BLOCK ////////////////////////////////
		
		//		private function setupIslandBlocker():void
		//		{
		//			if( IslandBlockPopup.checkIslandBlock( super.shellApi))// || true )	// TESTING :: Set to true automatically for testing
		//			{
		//				// get door interaction
		//				var door:Entity = super.getEntityById( "doorBedroomShrunk01" );
		//				var sceneInt:SceneInteraction = door.get( SceneInteraction );
		//				sceneInt.reached.removeAll();
		//				sceneInt.reached.add(openIslandBlock);
		//			}
		//		}
		//		
		//		private function openIslandBlock( ...args ):void
		//		{
		//			SceneUtil.lockInput(this, false);
		//			var blockPopup:IslandBlockPopup = super.addChildGroup( new IslandBlockPopup( "scenes/shrink/", super.overlayContainer ) ) as IslandBlockPopup;	
		//		}
		
		//////////////////////////////// SETUP ////////////////////////////////
		
		private function setUpBall():void
		{
			var clip:MovieClip = _hitContainer["tennisBall"];
			BitmapUtils.convertContainer(clip);
			var ball:Entity = _sceneObjectCreator.createCircle(clip, .7, _hitContainer, NaN, NaN, null, null, sceneData.bounds, this, null,null,150);
			ball.add(new WallCollider()).add(new PlatformCollider());
			
			MotionBounds(ball.get(MotionBounds)).box.left = 350;
		}
		
		override public function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == "look_at_blimp")	// called at end of dialogue
			{
				SceneUtil.setCameraTarget(this,getEntityById("doorMap"));
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, returnToGame));
			}
			if(event == "message_1_pt2")
			{
				if(!shellApi.checkHasItem(_shrinkEvents.THUMB_DRIVE))
					Dialog(player.get(Dialog)).sayById("message_1_pt2");
			}
			if(event == _shrinkEvents.LOOK_AWAY_TELESCOPE)
			{
				if(nearSchoolCoordinates(getEntityById("telescope").get(Telescope)))
				{
					if(shellApi.checkEvent(_shrinkEvents.CJ_AT_SCHOOL))
					{
						if(!shellApi.checkHasItem(_shrinkEvents.MORSE_CODE))
							Dialog(player.get(Dialog)).sayById("cantDecipher");
					}
					else
						Dialog(player.get(Dialog)).sayById("scienceRoom");
				}
				else
				{
					if(shellApi.checkEvent(_shrinkEvents.CJ_AT_SCHOOL))
						Dialog(player.get(Dialog)).sayById("wrongCoordinates");
				}
			}
			super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}
		
		private function setUpSchoolNote():void
		{
			var clip:MovieClip = _hitContainer["schoolNote"];
			BitmapUtils.convertContainer(clip);
			var note:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var interaction:Interaction = InteractionCreator.addToEntity(note, [InteractionCreator.CLICK], clip);
			interaction.click.add(thatsHerSchool);
			ToolTipCreator.addToEntity(note);
			Display(note.get(Display)).alpha = 0;
		}
		
		private function thatsHerSchool(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("thatsHerSchool");
		}
		
		private function setUpTelescope():void
		{
			var clip:MovieClip = _hitContainer["telescope"];
			if( !PlatformUtils.isDesktop )
			{
				convertContainer(clip["body"], PerformanceUtils.defaultBitmapQuality);
			}
			var telescope:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var scope:Telescope = new Telescope(-15,.25);
			telescope.add(new Id("telescope")).add(scope);
			Display(telescope.get(Display)).moveToBack();
			
			var offsets:Array = [new Point(0,-75), new Point(-50, -110), new Point(50, -110), new Point(240, -120)];
			
			var collider:Entity = getEntityById("teleHit");
			setUpHit(collider);
			
			var follow:FollowTarget = new FollowTarget(telescope.get(Spatial),1,false,true);
			follow.properties = new Vector.<String>();
			follow.properties.push("x","y","rotation");
			follow.offset = offsets[0];
			
			collider.add(follow);
			
			collider = getEntityById("scopeHit");
			setUpHit(collider);
			
			follow = new FollowTarget(telescope.get(Spatial),1,false,true);
			follow.properties = new Vector.<String>();
			follow.properties.push("x","y","rotation");
			follow.offset = offsets[3];
			
			InteractionCreator.addToEntity(collider,[InteractionCreator.CLICK]);
			var interaction:SceneInteraction = new SceneInteraction();
			interaction.offsetY = -100;
			interaction.minTargetDelta = new Point(25, 100);
			interaction.reached.addOnce(Command.create(lookInTelescope, scope));
			interaction.validCharStates = new <String>[CharacterState.STAND];
			
			collider.add(follow).add(interaction);
			
			ToolTipCreator.addToEntity(collider);
			
			for(var i:int = 1; i <= 2; i++)
			{
				collider = getEntityById("collider"+i);
				setUpHit(collider);
				
				var dial:Entity = EntityUtils.createSpatialEntity(this, clip["dial"+i], clip);
				dial.add(new WalkToTurnDial(collider,true,false,100,0,-.1)).add(new Id("dial"+i));
				Display(dial.get(Display)).moveToBack();
				
				collider.add(new SceneInteraction());
				InteractionCreator.addToEntity(collider,[InteractionCreator.CLICK]);
				interaction = collider.get(SceneInteraction);
				interaction.offsetY = -150;
				ToolTipCreator.addToEntity(collider);
				
				follow = new FollowTarget(telescope.get(Spatial),1,false,true);
				follow.properties = new Vector.<String>();
				follow.properties.push("x","y","rotation");
				follow.offset = offsets[i];
				collider.add(follow);
				
				scope.dials.push(dial.get(WalkToTurnDial));
				scope.displays.push(TextUtils.refreshText(clip["fldValue"+i], "Orange Kid"));
			}
		}
		
		private function setUpHit(entity:Entity):void
		{
			var display:Display = entity.get(Display);
			display.isStatic = false;
			display.visible = true;
			display.alpha = 0;
		}
		
		private function nearSchoolCoordinates(telescope:Telescope):Boolean
		{
			var PS_X:int = 87;
			var PS_Y:int = 16;
			
			var difference:Point = new Point(PS_X - telescope.dials[0].value, PS_Y - telescope.dials[1].value);
			
			if(Math.abs(difference.x) <= 1 && Math.abs(difference.y) <= 1)
				return true;
			return false;
		}
		
		private function lookInTelescope(player:Entity, scope:Entity, telescope:Telescope):void
		{
			if(nearSchoolCoordinates(telescope))
			{
				if(shellApi.checkEvent(_shrinkEvents.CJ_AT_SCHOOL) && shellApi.checkHasItem(_shrinkEvents.MORSE_CODE))
				{
					if(!shellApi.checkEvent(_shrinkEvents.GOT_CJS_MESSAGE_01) || !shellApi.checkEvent(_shrinkEvents.GOT_CJS_MESSAGE_02) && shellApi.checkEvent(_shrinkEvents.FLUSHED_THUMB_DRIVE))
						addChildGroup( new MorseCode( overlayContainer ))
					else
					{
						if(!shellApi.checkEvent(_shrinkEvents.FLUSHED_THUMB_DRIVE))
							Dialog(player.get(Dialog)).sayById("message_1");
						else
							Dialog(player.get(Dialog)).sayById("message_2");
					}
				}
				else
					addChildGroup(new TelescopePopup(overlayContainer,telescope.dials[0].value, telescope.dials[1].value));
			}
			else
				addChildGroup(new TelescopePopup(overlayContainer,telescope.dials[0].value, telescope.dials[1].value));
			
			addTelescopeInteraction();
		}
		
		private function addTelescopeInteraction(...args):void
		{
			var scopeHit:Entity = getEntityById("scopeHit");
			var scope:Telescope = getEntityById("telescope").get(Telescope);
			SceneInteraction(scopeHit.get(SceneInteraction)).reached.addOnce(Command.create(lookInTelescope, scope));
		}
		
		private function setUpMorseKey():void
		{
			var clip:MovieClip = _hitContainer["morseKey"];
			var morseKey:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var interaction:Interaction = InteractionCreator.addToEntity(morseKey, [InteractionCreator.CLICK], clip);
			interaction.click.add(getKey);
			ToolTipCreator.addToEntity(morseKey);
			Display(morseKey.get(Display)).alpha = 0;
			if(shellApi.checkHasItem(_shrinkEvents.MORSE_CODE))
				removeEntity(morseKey);
		}
		
		private function getKey(entity:Entity):void
		{
			removeEntity(entity);
			shellApi.getItem(_shrinkEvents.MORSE_CODE,null,true);
		}
		
		private function setUpPins():void
		{
			for(var i:int = 1; i <= 8; i++)
			{
				var clip:MovieClip = _hitContainer["pin"+i];
				var pin:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
				pin.add(new SceneInteraction()).add(new Id("pin"+i));
				InteractionCreator.addToEntity(pin,[InteractionCreator.CLICK],clip);
				var interaction:SceneInteraction = pin.get(SceneInteraction);
				interaction.offsetY = -125;
				ToolTipCreator.addToEntity(pin);
				Display(pin.get(Display)).alpha = 0;
			}
		}
		
		private function setUpBalloons():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var clip:MovieClip = _hitContainer["balloonVector"+i];
				var balloon:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				
				var rope:Entity = getEntityById("rope"+i);
				Display(rope.get(Display)).isStatic = false;
				rope.add(new Motion());//.add(new EntityIdList());
				
				var moveData:MovingHitData = new MovingHitData();
				moveData.velocity = 25;
				moveData.loop = true;
				var ropeSpatial:Spatial = rope.get(Spatial);
				var start:Point = new Point(ropeSpatial.x,ropeSpatial.y);
				moveData.points = [start, new Point(start.x, start.y + 100)];
				
				var mover:Mover = new Mover();
				mover.velocity = new Point(0, moveData.velocity);
				
				moveData.reachedPoint.add(Command.create(changeMoverVelocity, mover));
				rope.add(moveData).add(mover);//.add(new HitTest(Command.create(onBalloon, moverData), false, Command.create(offBalloon, moverData)));
				Display(rope.get(Display)).alpha = 0;
				
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = ropeSpatial;
				followTarget.rate = 1;
				balloon.add(followTarget);
			}
		}
		
		private function changeMoverVelocity(mover:Mover):void
		{
			mover.velocity.y *= -1;
		}
		
		private function setUpTrash():void
		{
			_trashPositions = new Vector.<Point>();
			
			var lowestPoint:Number = 1750;
			var spacing:Number = -150;
			var waveHeight:Number = 100;
			
			var interaction:Interaction;
			
			var clip:MovieClip = _hitContainer["garbage"];
			var garbage:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
			
			clip = _hitContainer["trashHit"];
			
			if(shellApi.checkEvent(_shrinkEvents.TIPPED_TRASH))
			{
				_hitContainer.removeChild(clip);
				Spatial(garbage.get(Spatial)).rotation = -90;
				removeEntity(getEntityById("trashCanStand"));
			}
			else
			{
				getEntityById("trashCanTipped").remove(Platform);
				
				var hit:Entity = _sceneObjectCreator.createBox(clip, 0, _hitContainer, NaN,NaN,null, null,sceneData.bounds, this, null, null, 200);
				var follow:FollowTarget = new FollowTarget(garbage.get(Spatial), 1, false, true);
				follow.offset = new Point(clip.width / 2, - clip.height / 2);
				hit.add(follow).add(new HitTest()).add(new EntityIdList()).add(new Id(clip.name));
				Display(hit.get(Display)).alpha = 0;
				var tip:Tip = new Tip(hit.get(HitTest), this, -45);
				tip.tipped.add(tipTrash);
				
				garbage.add(tip)
			}
			
			var moveData:MovingHitData;
			var paper:Entity;
			var paperSpatial:Spatial;
			var position:Point;
			
			for(var i:int = 1; i <= 4; i++)
			{
				clip = _hitContainer["paper"+i];
				paper = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				paper.add(new EntityIdList());
				Display(paper.get(Display)).moveToBack();
				TimelineUtils.convertClip(clip,this,paper,null,false);
				Timeline(paper.get(Timeline)).gotoAndStop(i%3);
				
				paperSpatial = paper.get(Spatial);
				
				position = new Point(paperSpatial.x, paperSpatial.y);
				_trashPositions.push(position);
				
				moveData = new MovingHitData();
				moveData.velocity = 100;
				moveData.loop = true
				moveData.pause 
				moveData.pause = !shellApi.checkEvent(_shrinkEvents.VENT_ON);
				moveData.points = [new Point(position.x, lowestPoint + spacing * i), new Point(position.x, lowestPoint + spacing * i - waveHeight)];
				
				paper.add(moveData).add(new WeakLift(.5, moveData)).add(new Id("paper"+i));
				
				if(!shellApi.checkEvent(_shrinkEvents.TIPPED_TRASH))
				{
					moveData.pause = true;
					Display(paper.get(Display)).visible = false;
					paperSpatial.x = Spatial(garbage.get(Spatial)).x - clip.width  / 2;
				}
				else
					paper.add(new Platform());
			}
			
			clip = _hitContainer["vent"];
			var vent:Entity;
			
			if( !shellApi.checkEvent( _shrinkEvents.VENT_ON ))
			{
				_hitContainer.removeChild( clip );
				
				clip = _hitContainer[ "heatVent" ];
				vent = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				interaction = InteractionCreator.addToEntity( vent, [ InteractionCreator.CLICK ], clip );
				interaction.click.add( ventsOff );
				ToolTipCreator.addToEntity( vent );
				Display( vent.get( Display )).alpha = 0;
			}
			else
			{
				vent = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
				Display( vent.get( Display )).moveToBack();
			
				// DO NOT ANIMATE THE VENT FOR LOWER END DEVICES
				if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_LOW )
				{
					var particle:VentParticle = new VentParticle();
					particle.init();
					var ventParticle:Entity = EmitterCreator.create(this, _hitContainer[ "vent" ], particle, 0,0,null, "ventParticle" );
					
					animateVent( vent );
				}
				
				clip = _hitContainer[ "heatVent" ];
				_hitContainer.removeChild( clip );
			}
		}
		
		private var skew:Boolean = false;
		
		private function animateVent(vent:Entity):void
		{
			skew = !skew;
			var scale:Number = 1;
			if(skew)
				scale = .95;
			
			TweenUtils.entityTo(vent, Spatial, 1, {scaleX:scale, ease:Linear.easeNone, onComplete:animateVent, onCompleteParams:[vent]});
		}
		
		private function ventsOff(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("vent_clicked");
		}
		
		private function tipTrash(trash:Entity):void
		{
			shellApi.completeEvent(_shrinkEvents.TIPPED_TRASH);
			
			removeEntity(getEntityById("trashCanStand"));
			removeEntity(getEntityById("trashHit"));
			trash.remove(Tip);
			
			getEntityById("trashCanTipped").add(new Platform());
			
			for(var i:int = 0; i < 4; i++)
			{
				var paper:Entity = getEntityById("paper"+(i+1));
				Display(paper.get(Display)).visible = true;
				paper.add(new Platform());
				
				TweenUtils.entityTo(paper, Spatial, 2, {x:_trashPositions[i].x, y:_trashPositions[i].y});
				if(shellApi.checkEvent(_shrinkEvents.VENT_ON))
					MovingHitData(paper.get(MovingHitData)).pause = false;
			}
		}
		
		private function setUpDust():void
		{
			var dustAsset:MovieClip;
			_dustArray = [];
			
			for(var number:int = 1; number < 3; number++ )
			{
				dustAsset = _hitContainer[ "dustball" + number ];
				_dustArray.push( BitmapUtils.createBitmapData( dustAsset ));
			}
			
			var dustPart:DustParticle = new DustParticle();
			dustPart.init( _dustArray );
			
			var dust:Entity = EmitterCreator.create( this, _hitContainer[ "dirtContainer" ], dustPart, 0, 0, null, "dust", null, false );
			
			var dirt:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "dirt" ], _hitContainer );
			dirt.add( new Id( "dirt" ));
			Display( dirt.get( Display )).moveToBack();
			
			var thumbDrive:Entity = EntityUtils.createSpatialEntity(this, _hitContainer[ "thumbDrive" ], _hitContainer);
			thumbDrive.add( new Id( "thumbDrive" )).add( new HitTheDeck( player.get( Spatial ), 100 ));
			Display( thumbDrive.get( Display )).moveToBack();
			HitTheDeck( thumbDrive.get( HitTheDeck )).duck.add( getThumbDrive );
			
			if( shellApi.checkItemEvent( _shrinkEvents.THUMB_DRIVE ))
			{
				removeEntity( thumbDrive );
				removeEntity( dirt );
			}
		}
		
		private function getThumbDrive( thumbDrive:Entity ):void
		{
			removeEntity( thumbDrive,true );
			shellApi.getItem( _shrinkEvents.THUMB_DRIVE, null, true );
		}
		
		private function setUpFan():void
		{
			var sideFan:SideFan = new SideFan(52.5,187.5, 720,20,.975,shellApi.checkEvent(_shrinkEvents.FAN_ON));
			super.loadFile( "fan_blade.swf", onBladeLoaded, sideFan );
		}
		
		private function cantPush(button:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("cantReach");
		}
		
		private function pressed(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			press.locked = true;
			shellApi.completeEvent(_shrinkEvents.FAN_DOWN);
			
			var button:Entity = getEntityById("fanButton");
			Interaction(button.get(Interaction)).click.remove(cantPush);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add(turnFanOnAndOff);
			sceneInteraction.validCharStates = new <String>[CharacterState.STAND];
			sceneInteraction.offsetX = -50;
			sceneInteraction.autoSwitchOffsets = false;
			button.add(sceneInteraction);
		}
		
		private function turnFanOnAndOff(player:Entity, button:Entity):void
		{
			if(!shellApi.checkEvent(_shrinkEvents.FAN_DOWN) || CurrentHit(player.get(CurrentHit)).hit != getEntityById("plug"))
				return;
			
			if(shellApi.checkEvent(_shrinkEvents.FAN_ON))
				shellApi.removeEvent(_shrinkEvents.FAN_ON);
			else
				shellApi.completeEvent(_shrinkEvents.FAN_ON);
			
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, PourPitcher);
			
			var time:Timeline = player.get(Timeline);
			
			var onComplete:LabelHandler;
			
			var fan:Entity = getEntityById("fan");
			var audio:Audio = fan.get(Audio);
			
			if(shellApi.checkEvent(_shrinkEvents.FAN_ON))
			{
				audio.play(FAN_SOUND, true, SoundModifier.POSITION);
				if(getEntityById("thumbDrive") != null)
					onComplete = time.handleLabel("ending",lookAtThumbDrive);
			}
			else
				audio.stop(FAN_SOUND, SoundType.EFFECTS);
			
			if(onComplete == null)
				time.handleLabel("ending", returnToGame);
			
			setFanState(fan.get(SideFan), getEntityById("bladeHit"));
		}
		
		private const FAN_SOUND:String = SoundManager.EFFECTS_PATH+"fan_engine_01_L.mp3";
		
		private function lookAtThumbDrive():void
		{
			var thumbDrive:Entity = getEntityById("thumbDrive");
			HitTheDeck(thumbDrive.get(HitTheDeck)).ignoreProjectile = false;
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, thumbDrive);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, returnToGame));
		}		
		
		private function returnToGame():void
		{
			FSMControl(player.get(FSMControl)).active = true;
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function setFanState(fan:SideFan, bladeCollider:Entity):void
		{
			fan.on = shellApi.checkEvent(_shrinkEvents.FAN_ON);
			
			var emitter:Emitter = getEntityById("dust").get(Emitter);
			
			if(!shellApi.checkEvent(_shrinkEvents.FAN_ON))
			{
				bladeCollider.remove(Hazard);
				bladeCollider.add(new Wall());
				emitter.emitter.counter.stop();
			}
			else
			{
				bladeCollider.add(_bladeHazard);
				bladeCollider.remove(Wall);
				emitter.start = true;
				emitter.emitter.counter.resume();
			}
			
			if(!shellApi.checkEvent(_shrinkEvents.FAN_DOWN))
				emitter.emitter.counter.stop();
			else
			{
				if(shellApi.checkEvent(_shrinkEvents.FAN_ON))
				{
					var dirt:Entity = getEntityById("dirt");
					if(dirt != null)
						removeEntity(dirt);
				}
			}
		}
		
		private function onBladeLoaded(asset:DisplayObjectContainer, sideFan:SideFan ):void//, fanPos:Spatial):void
		{
			var clip:MovieClip = _hitContainer[ "fan" ];
			if(PlatformUtils.isMobileOS)
			{
				convertContainer(clip,PerformanceUtils.defaultBitmapQuality);
			}
			var fan:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			fan.add(new Id("fan")).add(new Audio()).add(new AudioRange(1000,0,1,Quad.easeOut));
			
			var button:Entity = EntityUtils.createSpatialEntity(this, clip.fanButton, _hitContainer);
			button.add(new Id("fanButton"));
			var interaction:Interaction = InteractionCreator.addToEntity(button, [InteractionCreator.CLICK], clip.fanButton);
			
			if(shellApi.checkEvent(_shrinkEvents.FAN_DOWN))
			{
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add(turnFanOnAndOff);
				sceneInteraction.validCharStates = new <String>[CharacterState.STAND];
				sceneInteraction.offsetX = -50;
				sceneInteraction.autoSwitchOffsets = false;
				button.add(sceneInteraction);
			}
			else
				interaction.click.add(cantPush);
			
			ToolTipCreator.addToEntity(button);
			button.add(new FollowTarget(fan.get(Spatial)));
			FollowTarget(button.get(FollowTarget)).offset = new Point(-166,0);
			Display(button.get(Display)).alpha = 0;
			
			
			clip = asset as MovieClip;
			
			_sideData = BitmapUtils.createBitmapData(clip.sideBlade);
			_topData = BitmapUtils.createBitmapData(clip.topBlade);
			
			var sideBlade:Entity;
			var topBlade:Entity;
			var sprite:Sprite;
			var spatial:Spatial = fan.get( Spatial );
			
			for (var i:int = 0; i < 4; i++) 
			{
				sprite = BitmapUtils.createBitmapSprite(clip.sideBlade, 1, null, true, 0, _sideData);
				sprite.x = spatial.x;
				sprite.y = spatial.y;
				sideBlade = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
				
				sprite = BitmapUtils.createBitmapSprite(clip.topBlade, 1, null, true, 0, _topData)
				sprite.x = spatial.x;
				sprite.y = spatial.y;
				topBlade = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
				
				sideFan.addBlade(sideBlade, topBlade);
			}
			
			fan.add( sideFan );
			var fanCollider:Entity = getEntityById("fanCollider");
			fanCollider.add(new FollowTarget(fan.get(Spatial)));
			FollowTarget(fanCollider.get(FollowTarget)).offset = new Point(-50,-40);
			Display(fanCollider.get(Display)).isStatic = false;
			EntityUtils.visible(fanCollider, false);
			
			fan.add(new Press(new Point(1300,1610),fanCollider,100,0)).add(new Motion());
			if(shellApi.checkEvent(_shrinkEvents.FAN_DOWN))
				Press(fan.get(Press)).setPosition(fan.get(Spatial));
			Display(fan.get(Display)).moveToBack();
			
			Press(fan.get(Press)).pressed.add(pressed);
			
			var bladeCollider:Entity = getEntityById("bladeHit");
			_bladeHazard = bladeCollider.get(Hazard);
			bladeCollider.remove(Hazard);
			bladeCollider.add(new FollowTarget(fan.get(Spatial)));
			Display(bladeCollider.get(Display)).isStatic = false;
			EntityUtils.visible(bladeCollider, false);
			
			setFanState(fan.get(SideFan), bladeCollider);
		}
		
		private function setUpSeaMonkies():void
		{
			var tank:MovieClip = _hitContainer["seaBox"];
			for(var i:int = 1; i <= 3; i ++)
			{
				var clip:MovieClip = _hitContainer["seaMonkey"+i];
				if(PlatformUtils.isMobileOS)
					convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				var seaMonkey:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				seaMonkey.add(new SeaMonkey(tank.getBounds(_hitContainer) , player.get(Spatial)));
				Display(seaMonkey.get(Display)).moveToBack();
			}
		}
		
		private function setUpPendulums():void
		{
			
			for(var i:int = 1; i <= 5; i ++)
			{
				var clip:MovieClip = _hitContainer["pendulum"+i];
				if(PlatformUtils.isMobileOS)
				{
					convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
					continue;
				}
				var pendulum:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				var ball:Entity = EntityUtils.createSpatialEntity(this, clip.ball, _hitContainer);
				pendulum.add(new Swing()).add(new Pendulum(ball,90)).add(new Audio()).add(new AudioRange(1000, 0, 1, Quad.easeOut));
				Pendulum(pendulum.get(Pendulum)).hit.add(Command.create(triggerContact, pendulum));
			}
			Display(player.get(Display)).moveToFront();
		}
		
		private function triggerContact(pendulum:Entity):void
		{
			Audio(pendulum.get(Audio)).play(PENDULUM_TAP + GeomUtils.randomInt(1,4) + ".mp3", false, SoundModifier.POSITION);
		}
		
		private const PENDULUM_TAP:String = SoundManager.EFFECTS_PATH + "metal_ball_tap_0";
	}
}