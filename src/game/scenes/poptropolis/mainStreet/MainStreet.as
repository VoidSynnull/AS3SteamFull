package game.scenes.poptropolis.mainStreet
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.CameraZoomSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.motion.Proximity;
	import game.components.motion.Threshold;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.LabelHandler;
	import game.data.profile.TribeData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.Storm;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.scenes.poptropolis.mainStreet.components.ScreenShake;
	import game.scenes.poptropolis.mainStreet.systems.ScreenShakeSystem;
	import game.scenes.poptropolis.shared.TribeSelectPopup;
	import game.scenes.poptropolis.volcano.Volcano;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MainStreet extends PlatformerGameScene
	{
		private var _popEvents:PoptropolisEvents;
		private var _master:Entity;
		private var _frog:Entity;
		private var _frogStates:Array = ["blink", "croak", "swell", "jump"];

		private var tribeSelect:TribeSelectPopup;

		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/mainStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// Rick: need to bypass intro if using ad shortcut
			var lso:SharedObject = SharedObject.getLocal("Char","/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			// if login name starts with TESTGUEST (only used for ad shortcut)
			var skipIntro:Boolean = ((lso.data.login) && (lso.data.login.substr(0,9) == "TESTGUEST"));
			trace("adShortCut: skipIntro: " + skipIntro);
			if ((!this.shellApi.checkEvent(_popEvents.POPTROPOLIS_STARTED)) && (!skipIntro))
			{
				this.shellApi.completeEvent(_popEvents.POPTROPOLIS_STARTED);
				this.shellApi.loadScene(Volcano, 0, 0, null, 0, 0);
				return;
			}
			
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(1570, 1340),"minibillboard/minibillboardMedLegs.swf");	

			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			_master = this.getEntityById("master");		
			getEntityById("char2").add(new PlatformDepthCollider());
			_popEvents = this.events as PoptropolisEvents; 
			
			setupFrog();
			setupRain();
			setupMaster();
			setupTribeMemberAndColumn();
			
			if(!this.shellApi.checkEvent(_popEvents.SELECTED_TRIBE))
			{			
				var target:Spatial = new Spatial(1200, 550);
				
				CameraZoomSystem(this.getSystem(CameraZoomSystem)).scaleTarget = 0.8;
				this.shellApi.camera.scale = 0.8;
				this.shellApi.camera.target = target;
				
				var tween:Tween = new Tween();
				this.player.add(tween);
				tween.to(target, 8, {y:1100, ease:Quad.easeInOut, onComplete:this.introFinished});
			}
			else
			{
				selectTribe();
				setupEarthquake();
			}
		}
		
		private function introFinished():void
		{
			CameraZoomSystem(this.getSystem(CameraZoomSystem)).scaleTarget = 1;
			this.shellApi.camera.scale = 1;
			
			selectTribe();
			setupEarthquake();
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		////////////////////////////////////////////////////////////////////
		/////////////////////////// SELECT TRIBE ///////////////////////////
		////////////////////////////////////////////////////////////////////
		
		private function selectTribe():void
		{
			var tribeData:TribeData = TribeUtils.getTribeOfPlayer( super.shellApi );
			if( tribeData == null )		//tribe not selected, open popup for selection
			{
				var  tribeSelectPopup:TribeSelectPopup = super.addChildGroup( new TribeSelectPopup( "scenes/poptropolis/shared/tribeSelectPopup.swf", super.overlayContainer ) ) as TribeSelectPopup;
				tribeSelectPopup.onTribeSelected.add( tribeSelected );
			}
			else						//tribe already selected, give jersey
			{
				tribeSelected( tribeData );
			}
		}
		
		private function tribeSelected( tribeData:TribeData ):void
		{
			/**
			 * You're getting the jersey so fast, it's causing the camera to freak out and not position itself near the
			 * player fast enough. Put a half second delay for the jersey item so things stop being nuts!
			 */
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, this.getJersey));
			this.shellApi.completeEvent(_popEvents.SELECTED_TRIBE);
			
			//Replace the Dialog [tribe] tag with the player's correct tribe name.
			if( _master )
			{
				var dialog:Dialog = _master.get(Dialog);
				if( dialog )
				{
					var data:DialogData = dialog.getDialog("late");
					data.dialog = data.dialog.replace("[tribe]", tribeData.name);
				}
			}
		}
		
		private function getJersey():void
		{
			super.shellApi.getItem( "tribal_jersey", null, true );	// give jersey item
		}
		
		private function setupEarthquake():void
		{
			var shake:ScreenShakeSystem = new ScreenShakeSystem();
			shake.playAudio.add(this.playerAudio);
			this.addSystem(shake);
			
			var target:Spatial = new Spatial();
			this.shellApi.camera.target = target;
			this.player.add(new ScreenShake(target));
		}
		
		private function playerAudio(boolean:Boolean):void
		{
			if(boolean) AudioUtils.play(this, SoundManager.EFFECTS_PATH + "earthquake_alt_01.mp3", 1, true, [SoundModifier.EFFECTS]);
			else AudioUtils.getAudio(this).stop(SoundManager.EFFECTS_PATH + "earthquake_alt_01.mp3");
		}
		
		///////////////////////////////////////////////////////////////////////////
		//////////////////////////////// SETUP FROG ///////////////////////////////
		///////////////////////////////////////////////////////////////////////////
		
		/**
		 * Stupid frog animations... At least I didn't have to make a system.
		 */
		private function setupFrog():void
		{
			_frog = this.getEntityById("interaction1");
			
			var audio:Audio = new Audio();
			_frog.add(audio);
			
			audio.play(SoundManager.EFFECTS_PATH + "single_frog_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			_frog.add(new AudioRange(800));
			
			var clip:MovieClip = this._hitContainer["interaction1"];
			TimelineUtils.convertClip(clip, this, _frog);
			
			var timeline:Timeline = _frog.get(Timeline);
			timeline.playing = false;
			
			var display:Display = _frog.get(Display);
			display.syncedWithSpatial = true;
			
			var sleep:Sleep = _frog.get(Sleep);
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			var interation:SceneInteraction = _frog.get(SceneInteraction);
			interation.approach = false;
			interation.triggered.add(handleFrogClick);
			
			this.handleFrogAnimationEnd();
		}
		
		private function handleFrogAnimationEnd(...args):void
		{
			var delay:Number = Utils.randNumInRange(1, 1);
			var state:String = _frogStates[Utils.randInRange(0, _frogStates.length - 2)];
			SceneUtil.addTimedEvent(this, new TimedEvent(delay, -1, Command.create(this.updateFrog, state)));
		}
		
		private function updateFrog(state:String):void
		{
			var timeline:Timeline = _frog.get(Timeline);
			if(timeline.playing) return;
			timeline.gotoAndPlay(state);
			timeline.handleLabel("blink", handleFrogAnimationEnd);
		}
		
		private function handleFrogClick(player:Entity, frog:Entity):void
		{
			var audio:Audio = _frog.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "clickable_frog_01.mp3", false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			
			var timeline:Timeline = _frog.get(Timeline);
			timeline.labelHandlers = new Vector.<LabelHandler>();
			timeline.gotoAndPlay("jump");
			timeline.handleLabel("jumpland", hitSand);
			timeline.handleLabel("blink", handleFrogJumpEnd);
		}
		
		private function hitSand():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ls_sand_0" + Utils.randInRange(1, 2) + ".mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function handleFrogJumpEnd():void
		{
			var spatial:Spatial = _frog.get(Spatial);
			spatial.x -= 224;
			
			var clip:MovieClip = this._hitContainer["interaction1"];
			clip.x -= 224;
			
			this.handleFrogAnimationEnd();
		}
		
		///////////////////////////////////////////////////////////////////////////
		//////////////////////////////// SETUP RAIN ///////////////////////////////
		///////////////////////////////////////////////////////////////////////////
		
		/**
		 * Rain
		 */
		private function setupRain():void
		{
			var sprite:Sprite = new Sprite();
			
			sprite.mouseEnabled = false;
			sprite.mouseChildren = false;
			sprite.x = -this.shellApi.viewportWidth * 0.5;
			sprite.y = -this.shellApi.viewportHeight * 0.5;
			this.groupContainer.addChild(sprite);
			
			var colors:Array = [0xC8FAFF];
			var random:Random = new Random(1, 5);
			var box:RectangleZone = new RectangleZone(0, 0, this.shellApi.viewportWidth * 2, this.shellApi.viewportHeight);
			
			var rain:Storm = new Storm();
			rain.init(random, Droplet, [3], box, new RectangleZone(0, 0, 0, 200), new Point(0, 650), new Point(100, 0), colors, 0.5, true);
			
			var entity:Entity = EmitterCreator.create(this, sprite, rain, -box.right/2, -box.bottom/2, null, "rain");
		}
		
		////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////// SETUP MASTER ///////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Master
		 */
		private function setupMaster():void
		{
			if(this.shellApi.checkEvent(_popEvents.STARTED_GAMES))
				this.removeEntity(this.getEntityById("master"));
			else
			{
				this.addSystem(new ProximitySystem());
				
				_master = this.getEntityById("master");
				this.shellApi.eventTriggered.add(handleEventTriggered);
				
				if(!this.shellApi.checkEvent(_popEvents.TALKED_TO_MC))
				{
					var proximity:Proximity = new Proximity(300, this.player.get(Spatial));
					proximity.entered.addOnce(handleNearMaster);
					this._master.add(proximity);
					
					var door:Entity = this.getEntityById("doorAdGroundH22");
					var interaction:SceneInteraction = door.get(SceneInteraction);
					interaction.approach = false;
					interaction.triggered.addOnce(this.handleDoorClick);
				}
			}
		}
		
		private function handleDoorClick(player:Entity, door:Entity):void
		{
			SceneUtil.lockInput(this);
			this.shellApi.camera.target = this._master.get(Spatial);
			Dialog(this._master.get(Dialog)).sayById("meet_you");
		}
		
		private function handleNearMaster(master:Entity):void
		{
			this.removeSystemByClass(ProximitySystem);
			
			var sleep:Sleep = this._master.get(Sleep);
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			this.player.remove(Threshold);
			CharUtils.lockControls(this.player);
			
			var dialog:Dialog = _master.get(Dialog);
			dialog.sayById("late");
		}
		
		private function setupTribeMemberAndColumn():void
		{
			var interaction:SceneInteraction;
			var entity:Entity;
			
			entity = this.getEntityById("tribeMember");
			interaction = entity.get(SceneInteraction);
			interaction.reached.add(this.sayTribeDialog);
			
			entity = this.getEntityById("columnInteraction");
			interaction = entity.get(SceneInteraction);
			interaction.approach = false;
			interaction.triggered.add(this.sayTribeDialog);
		}
		
		private function sayTribeDialog(player:Entity, entity:Entity):void
		{
			var npc:Entity = this.getEntityById("tribeMember");
			var dialog:Dialog = npc.get(Dialog);
			dialog.sayById("hail");
			dialog.complete.addOnce(this.sayTribeResponse);
		}
		
		private function sayTribeResponse(data:DialogData):void
		{
			var dialog:Dialog = this.player.get(Dialog);
			
			var playerTribe:TribeData = TribeUtils.getTribeOfPlayer(shellApi);
			if(playerTribe && playerTribe.id == TribeUtils.WILDFIRE)
			{
				dialog.sayById("best");
			}
			else 
			{
				dialog.sayById("beaten");
			}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "run")
			{
				this.shellApi.camera.target = this._master.get(Spatial);
				CharUtils.followPath( _master, new <Point> [new Point(4200, 1705)], handleRunComplete);
			}
			if(event == "unlock_door")
			{
				this.shellApi.camera.target = this._master.get(Spatial);
				CharUtils.followPath( _master, new <Point> [new Point(4200, 1705)], unlockDoor);
			}
			else if(event == "games")
			{
				Dialog(this._master.get(Dialog)).sayById("games");
			}
			else if(event == "talked_to_mc")
			{
				CharUtils.lockControls(this.player, false, false);
				CharUtils.stateDrivenOn(this.player);
			}
		}
		
		private function handleRunComplete(master:Entity):void
		{
			CharUtils.lockControls(this.player, false, false);
			CharUtils.stateDrivenOn(this.player);
			
			this.shellApi.completeEvent(_popEvents.TALKED_TO_MC);
			this.shellApi.camera.target = this.player.get(Spatial);
			this.removeEntity(master);
			
			var door:Entity = this.getEntityById("doorAdGroundH22");
			var interaction:SceneInteraction = door.get(SceneInteraction);
			interaction.approach = true;
			interaction.triggered.remove(this.handleDoorClick);
		}
		
		private function unlockDoor(master:Entity):void
		{
			var door:Entity = this.getEntityById("doorAdGroundH22");
			Door(door.get(Door)).open = true;
		}
	}
}