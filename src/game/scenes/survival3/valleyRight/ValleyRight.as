package game.scenes.survival3.valleyRight
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.PulleyConnecter;
	import game.components.motion.PulleyObject;
	import game.components.motion.PulleyRope;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Knock;
	import game.data.animation.entity.character.Place;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.shared.Survival3Scene;
	import game.scenes.survival3.shared.components.RadioSignal;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.PulleySystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class ValleyRight extends Survival3Scene
	{
		public function ValleyRight()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival3/valleyRight/";
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
			shellApi.eventTriggered.add(handleEventTrigger);
			setupBranches();
			if(super.shellApi.checkHasItem(_events.POCKET_KNIFE))
			{
				removeKnifeBranch();
			}
			else
			{
				setupKnife();
			}
			
			setupPulley();
			if(shellApi.checkEvent(_events.PULLEY_BRANCH_BROKE))
			{
				if(shellApi.checkItemEvent(_events.LEMON))
				{
					// Hide everything if we already have the lemons
					hidePulley(true);
				}
				else if(shellApi.checkEvent(_events.CRATE_SMASHED))
				{
					hidePulley(false);
				}
				else
				{
					// activate the pulley
					startPulley();
				}
			}
			
			setupPlane();
			setupNails();
			
			super.loaded();
			
			RadioSignal(player.get(RadioSignal)).groundLevel += 1000;
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			// Player used the saw
			if(event == _events.USE_SAW)
			{
				var playerSpatial:Spatial = player.get(Spatial);
				// if the branch isn't broken, check if we are in the vicinity to cut it
				if(!shellApi.checkEvent(_events.PULLEY_BRANCH_BROKE))
				{
					if(playerSpatial.x > 1840 && playerSpatial.x < 2330)
					{
						if(playerSpatial.y > 640 && playerSpatial.y < 815)
						{
							// we are in the right area - move to spot to cut branch
							SceneUtil.lockInput(this, true);
							CharUtils.moveToTarget(this.player, 2200, playerSpatial.y, false, readyToCutPulleyBranch, new Point(30, 100)).validCharStates = new <String>[CharacterState.STAND];
							return;
						}
					}
				}
				else
				{
					// branch is broken so check if we are on the branch and its low enough to cut it
					if(!shellApi.checkEvent(_events.CRATE_SMASHED))
					{
						var branchSpatial:Spatial = _pulleyBranch.get(Spatial);
						// on branch
						if(Math.abs(playerSpatial.y - (branchSpatial.y - branchSpatial.height/2)) < 10)
						{
							if(Math.abs(playerSpatial.x - branchSpatial.x) < branchSpatial.width/2)
							{
								if(branchSpatial.y > 1200)
								{
									this.removeSystemByClass(PulleySystem);
									_branchPlatform.get(Audio).stop(SoundManager.EFFECTS_PATH + "drag_rope_01_loop.mp3");
									_branchPlatform.get(Motion).velocity.y = 0;
									
									SceneUtil.lockInput(this, true);
									CharUtils.moveToTarget(this.player, 1980, playerSpatial.y, false, readyToCut, new Point(30, 100)).validCharStates = new <String>[CharacterState.STAND];
									return;
								}
								
								var dialog:Dialog = player.get(Dialog);
								dialog.sayById("not_here");
								return;
							}							
						}
					}
				}	
				
				var pDialog:Dialog = player.get(Dialog);
				pDialog.sayById("no_use");
			}
			else if(event == _events.USE_SCREWDRIVER)
			{
				var playerDialog:Dialog = player.get(Dialog);
				playerDialog.sayById("no_use");
			}
			else if(event == _events.RADIO)
			{
				var wrongRadio:Dialog = player.get(Dialog);
				wrongRadio.sayById("radio_wrong");
			}
		}
		
		private function readyToCutPulleyBranch(player:Entity):void
		{
			CharUtils.setDirection(player, false);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "armyknife", false);
			CharUtils.setAnim(player, Place);
			CharUtils.getTimeline(player).handleLabel("ending", breakPulleyBranch);
		}
		
		private function breakPulleyBranch():void
		{
			SceneUtil.lockInput(this, false, false);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM, true);
			shellApi.triggerEvent(_events.PULLEY_BRANCH_BROKE, true);
			startPulley();
		}
		
		// Setup the base structure of the pulley but don't start it yet
		private function setupPulley():void
		{
			var pulleyConnector:PulleyConnecter = new PulleyConnecter();
			_boxPlatform = getEntityById("boxPlatform");
			_branchPlatform = getEntityById("branchPlatform");
			_boxPlatform.add(pulleyConnector);
			_branchPlatform.add(pulleyConnector);
			
			var boxPulleyObject:PulleyObject = new PulleyObject(_branchPlatform, 1524);
			boxPulleyObject.startMoving.add(pulleyStartMoving);
			boxPulleyObject.stopMoving.add(pulleyStopMoving);
			_boxPlatform.add(boxPulleyObject);
			_boxPlatform.add(new Audio());
			_boxPlatform.add(new AudioRange(1000));
			
			var branchPulleyObject:PulleyObject = new PulleyObject(_boxPlatform, 1524);
			branchPulleyObject.startMoving.add(pulleyStartMoving);
			branchPulleyObject.stopMoving.add(pulleyStopMoving);
			_branchPlatform.add(branchPulleyObject);
			_branchPlatform.add(new Audio());
			_branchPlatform.add(new AudioRange(1000));
			
			_lemonBox = getEntityById("lemonBox");
			if(!PlatformUtils.isDesktop) DisplayUtils.bitmapDisplayComponent(_lemonBox, true, 1);
			InteractionCreator.addToEntity(_lemonBox, [InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(_lemonBox);
			var interaction:Interaction = _lemonBox.get(Interaction);
			interaction.click.add(lemonBoxClicked);
			
			_rope1 = EntityUtils.createSpatialEntity(this, _hitContainer["rope1"]);
			_rope1.add(new PulleyRope(_rope1.get(Spatial), _lemonBox.get(Spatial)));
			
			_pulleyBranch = getEntityById("pulleyBranch");
			if(!PlatformUtils.isDesktop) DisplayUtils.bitmapDisplayComponent(_pulleyBranch, true, 1);
			_rope2 = EntityUtils.createSpatialEntity(this, _hitContainer["rope2"]);
			_rope2.add(new PulleyRope(_rope2.get(Spatial), _pulleyBranch.get(Spatial)));
			
			_hitContainer["lemonBoxAnimated"].mouseEnabled = false;
			_hitContainer["lemonBoxAnimated"].mouseChildren = false;
			_animatedBox = EntityUtils.createSpatialEntity(this, _hitContainer["lemonBoxAnimated"]);
			_animatedBox = TimelineUtils.convertClip(_hitContainer["lemonBoxAnimated"], this, _animatedBox, null, false);
			
			_coilRope = EntityUtils.createSpatialEntity(this, _hitContainer["coilRope"]);
			_coilRope = TimelineUtils.convertClip(_hitContainer["coilRope"], this, _coilRope, null, false);
			_coilRope.get(Display).visible = false;
		}
		
		private function pulleyStartMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "drag_rope_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function pulleyStopMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.stop(SoundManager.EFFECTS_PATH + "drag_rope_01_loop.mp3");
		}
		
		private function startPulley():void
		{
			var branchSpatial:Spatial = _pulleyBranch.get(Spatial);
			branchSpatial.rotation += 3;
			
			var platformSpatial:Spatial = _branchPlatform.get(Spatial);
			platformSpatial.rotation += 3;
			platformSpatial.x -= 25;
			
			_boxPlatform.add(new Mass(150));
			_branchPlatform.add(new Mass(30));
			this.player.add(new Mass(200));
			this.addSystem(new PulleySystem(), SystemPriorities.checkCollisions);
		}
		
		private function readyToCut(player:Entity):void
		{
			CharUtils.setDirection(this.player, true);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM2, "armyknife", false);
			CharUtils.setAnim(player, Knock);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "cutting_rope_01_loop.mp3", 1, true);
			CharUtils.getTimeline(this.player).handleLabel("ending", breakPulley);
		}
		
		// After animation is complete of cutting the rope, break branch off
		private function breakPulley():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "cutting_rope_01_loop.mp3");
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM2, true);
			this.addSystem(new ThresholdSystem());
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rope_snap_01.mp3");
			
			_rope2.remove(PulleyRope);
			var motion:Motion = new Motion();
			motion.acceleration.y = -800;
			_rope2.add(motion);
			
			this.removeEntity(_branchPlatform, true);
			var branchThreshold:Threshold = new Threshold("y", ">");
			branchThreshold.threshold = 1640;
			branchThreshold.entered.add(stopBranch);
			_pulleyBranch.add(branchThreshold);
			var branchMotion:Motion = new Motion();
			branchMotion.acceleration.y = 800;
			_pulleyBranch.remove(FollowTarget);
			_pulleyBranch.add(branchMotion);
			
			_rope1.remove(PulleyRope);
			Spatial(_rope1.get(Spatial)).rotation = 180;
			var rope1Follow:FollowTarget = new FollowTarget(_boxPlatform.get(Spatial));
			_rope1.add(rope1Follow);
			_boxPlatform.get(Motion).acceleration.y = 800;
			
			var boxThreshold:Threshold = new Threshold("y", ">");
			boxThreshold.threshold = 1530;
			boxThreshold.entered.addOnce(smashCrate);
			_boxPlatform.add(boxThreshold);	
		}
		
		// Only do this if they have the lemon card already
		private function hidePulley(gotLemons:Boolean = true):void
		{
			removeEntity(_rope1);
			removeEntity(_rope2);
			removeEntity(_branchPlatform);
			removeEntity(_pulleyBranch);
			removeEntity(_boxPlatform);
			removeEntity(_lemonBox);
			
			var spatial:Spatial = _animatedBox.get(Spatial);
			spatial.x = 1841;
			spatial.y = 1525;
			
			if(gotLemons)
			{
				_animatedBox.get(Timeline).gotoAndStop("noLemon");
				removeEntity(_coilRope);
			}
			else
			{
				_animatedBox.get(Timeline).gotoAndStop("withLemon");				
				createLemonInteraction();
			}
			
			_hitContainer.removeChild(_hitContainer.getChildByName("topRope"));			
		}
		
		private function stopBranch():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_impact_01.mp3");
			
			var motion:Motion = _pulleyBranch.get(Motion);
			if(motion.velocity.y * .5 < 100)
			{
				motion.velocity.y = 0;
				motion.acceleration.y = 0;
				_pulleyBranch.remove(Motion);
			}
			else
			{
				motion.velocity.y *= -.5
			}
		}
		
		private function smashCrate():void
		{
			_hitContainer.removeChild(_hitContainer.getChildByName("topRope"));
			removeEntity(_rope2, true);
			_coilRope.get(Display).visible = true;
			_coilRope.get(Timeline).play();
			
			_boxPlatform.get(Motion).velocity.y = 0;
			this.removeEntity(_boxPlatform, true);
			
			var lemonSpatial:Spatial = _lemonBox.get(Spatial);
			var animatedSpatial:Spatial = _animatedBox.get(Spatial);
			
			animatedSpatial.x = lemonSpatial.x;
			animatedSpatial.y = 1530;
			
			shellApi.triggerEvent(_events.CRATE_SMASHED, true);
			
			var boxTimeline:Timeline = _animatedBox.get(Timeline);
			boxTimeline.gotoAndPlay("smash");
			boxTimeline.handleLabel("withLemon", boxBroken);
			
			removeEntity(_lemonBox, true);
			removeEntity(_rope1, true);
		}
		
		private function boxBroken():void
		{
			// Setup click area
			this.removeSystemByClass(ThresholdSystem);
			
			createLemonInteraction();
			SceneUtil.lockInput(this, false, false);
		}
		
		private function lemonBoxClicked(button:Entity):void
		{
			var playerDialog:Dialog = player.get(Dialog);
			playerDialog.sayById("crate_sealed");
		}
		
		private function setupNails():void
		{
			var nails:Entity = this.getEntityById("nailsInteraction");
			if(shellApi.checkItemEvent(_events.NAIL))
			{
				var display:Display = nails.get(Display);
				display.displayObject.mouseEnabled = false;
				display.displayObject.mouseChildren = false;
				display.displayObject = null;			
				removeEntity(nails);
			}
			else
			{
				var interaction:SceneInteraction = nails.get(SceneInteraction);
				interaction.reached.addOnce(giveNail);
			}
		}
		
		private function giveNail(char:Entity, nails:Entity):void
		{
			var display:Display = nails.get(Display);
			display.displayObject.mouseEnabled = false;
			display.displayObject.mouseChildren = false;
			display.displayObject = null;			
			removeEntity(nails);
			
			shellApi.getItem(_events.NAIL, null, true);
		}
		
		private function createLemonInteraction():void
		{			
			var itemGroup:ItemGroup = new ItemGroup();
			itemGroup.setupScene(this);
			var lemon:Entity = itemGroup.addSceneItemFromDisplay(_hitContainer["lemonClick"], "lemon");
			DisplayUtils.moveToTop(lemon.get(Display).displayObject);
			
			var itemHitSystem:ItemHitSystem = new ItemHitSystem();
			addSystem(itemHitSystem);
			itemHitSystem.gotItem.add(Command.create(gotLemons, itemHitSystem));
		}
		
		private function gotLemons(item:Entity, itemHitSystem:ItemHitSystem):void
		{
			if(item.get(Id).id== "lemon")
			{
				itemHitSystem.gotItem.removeAll();
				removeSystem(itemHitSystem, true);
				
				_animatedBox.get(Timeline).gotoAndStop("noLemon");
				shellApi.getItem(_events.LEMON, null, true);
			}
		}
				
		private function setupKnife():void
		{
			_knifeBranch = TimelineUtils.convertClip(_hitContainer["knifeBranch"], this, null, null, false);
			var knife:Entity = getEntityById("knifeInteraction");
			var interaction:SceneInteraction = knife.get(SceneInteraction);
			interaction.reached.add(knifeClick);			
		}
		
		private function knifeClick(char:Entity, knife:Entity):void
		{
			if(player.get(Spatial).y < 1360)
			{
				SceneUtil.lockInput(this, true, true);
				CharUtils.setAnim(this.player, Place);
				
				var timeline:Timeline = CharUtils.getTimeline(this.player);
				timeline.handleLabel("trigger", pickUpKnife, true);
				timeline.handleLabel("ending", knifePulled, true);
			}
		}
		
		// When halfway through, give the knife to the player
		private function pickUpKnife():void
		{
			_knifeBranch.get(Timeline).gotoAndPlay("bend");
			SkinUtils.setSkinPart(this.player, SkinUtils.ITEM, "armyknife");
			this.removeEntity(this.getEntityById("knifeInteraction"));
		}
		
		// Once the player is done picking up the knife, show the card
		// and break the branch, playing its animation
		private function knifePulled():void
		{
			shellApi.getItem(_events.POCKET_KNIFE, null, true);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "branch_break_01.mp3");
			this.removeEntity(this.getEntityById("breakBranch"));
			
			var branchTimeline:Timeline = _knifeBranch.get(Timeline);
			branchTimeline.gotoAndPlay("fall");
			branchTimeline.handleLabel("hitGround", branchFell);
			
			SkinUtils.setSkinPart(this.player, SkinUtils.ITEM, "empty");
			
			var playerFSM:FSMControl = player.get(FSMControl);
			playerFSM.setState(CharacterState.STAND);
			CharUtils.stateDrivenOn(player);
			
			SceneUtil.lockInput(this, false, false);
		}
		
		private function branchFell():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_impact_01.mp3");
		}
		
		// remove the branch and knife
		private function removeKnifeBranch():void
		{
			_hitContainer.removeChild(_hitContainer["knifeBranch"]);
			this.removeEntity(this.getEntityById("knifeInteraction"));
			this.removeEntity(this.getEntityById("breakBranch"));
		}
		
		private function setupPlane():void
		{
			var planeZone:Zone = getEntityById("planeZone").get(Zone);
			planeZone.entered.add(planeEntered);
			planeZone.exitted.add(planeExited);
			
			_planeFront = BitmapUtils.createBitmap(_hitContainer["plane"]);	
			DisplayUtils.swap(_planeFront, _hitContainer["plane"]);
			DisplayUtils.moveToTop(_planeFront);			
		}
		
		// Hide the exterior of the plane when in the zone
		private function planeEntered(zoneId:String, charId:String):void
		{
			if(player.get(Motion).velocity.y >= 0)
				_planeFront.visible = false;			
		}
		
		private function planeExited(zoneId:String, charId:String):void
		{
			if(player.get(Spatial).x < 1280)
				_planeFront.visible = true;			
		}
		
		// When the player cuts the rope on the pulley, play an animation
		// Then make the branch and crates fall and break
		private function cutRope():void
		{
			SceneUtil.lockInput(this, true, true);
		}
		
		// Setup the branches to function with the spring branch system
		private function setupBranches():void
		{
			var entity:Entity;
			var timeline:Timeline;
			
			for (var i:Number = 0; i < 2; i++)
			{
				var clip:MovieClip = MovieClip(this._hitContainer)["branch" + i];
				var bounceEntity:Entity = this.getEntityById( "bounce" + i );
				
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
				
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			}
			this.addSystem(new TriggerHitSystem());
		}
		
		override public function destroy():void
		{
			_planeFront.bitmapData.dispose();
			_planeFront.bitmapData = null;
			super.destroy();
		}
		
		private var _knifeBranch:Entity;
		private var _planeFront:Bitmap;
		private var _events:Survival3Events;
		
		// Pulley
		private var _boxPlatform:Entity;
		private var _branchPlatform:Entity;
		private var _lemonBox:Entity;
		private var _animatedBox:Entity;
		private var _pulleyBranch:Entity;
		private var _rope1:Entity;
		private var _rope2:Entity;
		private var _coilRope:Entity;
	}
}