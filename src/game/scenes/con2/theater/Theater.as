package game.scenes.con2.theater
{
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Trip;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.character.AddBalloon;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scenes.carnival.mirrorMaze.particles.MirrorBreak;
	import game.scenes.con2.shared.Poptropicon2Scene;
	import game.scenes.custom.AdMiniBillboard;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.FallState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.entity.character.states.touch.SkidState;
	import game.systems.entity.character.states.touch.StandState;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.popup.IslandEndingPopup;
	import game.ui.showItem.ShowItem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Theater extends Poptropicon2Scene
	{
		private var emcee:Entity;
		private var superhero:Entity;
		private var viking:Entity;
		private var hippie:Entity;
		private var panTarget:Entity;
		private var contestant1:Entity;
		private var contestant2:Entity;
		private var omegon:Entity;
		private var teleporter:Entity;
		private var chairs:Entity;
		private var oMotion:Motion;
		private var hMotion:Motion;
		private var henchbot:Entity;
		
		private var eyeBeam:Entity;
		private var pyramid:Entity;
		
		private var card:Entity;
		
		public var colorGlow:GlowFilter = new GlowFilter( 0x00FF00, 0, 40, 40, 1, 1 );
		private var currShakeTime:Number = 7;
		
		private var mirrorEmitter:MirrorBreak;
		private var mirrorEmitterEntity:Entity;
		private var mirrorTarget:Entity;
		
		public function Theater()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/theater/";
			
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
			super.shellApi.eventTriggered.add(handleEventTriggered);
			this.emcee = this.getEntityById("emcee");
			
			if(!this.shellApi.checkEvent( _events.SAW_START_POPUP )){
				//remove balloon if the player has it
				CharUtils.removeSpecialAbilityByClass(player, AddBalloon, true);
				
				SceneUtil.lockInput(this, true);
				emcee.get(Spatial).x += 150;
				CharUtils.setDirection(player, false);
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, runOpeningDialog, true));
				setupGlassBreak();
				cardManager.updateDeck("", shellApi.island);// reset deck
			}
			if(this.getEntityById("superhero")){
				this.superhero = this.getEntityById("superhero");
				superhero.get(Dialog).faceSpeaker = false;
			}
			if(this.getEntityById("viking")){
				this.viking = this.getEntityById("viking");
			}
			if(this.getEntityById("hippie")){
				this.hippie = this.getEntityById("hippie");
			}
			if(this.getEntityById("contestant1")){
				this.contestant1 = this.getEntityById("contestant1");
			}
			if(this.getEntityById("contestant2")){
				this.contestant2 = this.getEntityById("contestant2");
			}
			if(this.getEntityById("omegon"))
			{
				this.omegon = this.getEntityById("omegon");
				if(!AppConfig.mobile)
				{
					omegon.get(Display).displayObject.filters = new Array( colorGlow );
				}
				eyeBeam = EntityUtils.createSpatialEntity(this, _hitContainer["eyeBeam"]);
				eyeBeam.add(new Tween());
				eyeBeam.get(Display).alpha = 0;
				
				var pClip:MovieClip = _hitContainer["pyramid"];
				BitmapUtils.convertContainer(pClip);
				pyramid = EntityUtils.createSpatialEntity(this, _hitContainer["pyramid"]);
				var follow:FollowTarget = new FollowTarget(Spatial(omegon.get(Spatial)), .02);
				follow.properties = new <String>["x","y"];
				pyramid.add(follow);
				pyramid.add(new SpatialOffset());
				pyramid.get(SpatialOffset).x = 40;
				pyramid.get(SpatialOffset).y = -50;
				pyramid.add(new Tween());
				pyramid.get(Display).alpha = 0;				
			}
			
			if(this.getEntityById("henchbot")){
				this.henchbot = this.getEntityById("henchbot");
			}
			
			if(this.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.MEDAL_CON2 )){
				this.removeEntity(omegon);
				this.removeEntity(contestant1);
				this.removeEntity(contestant2);
				this.removeEntity(henchbot);
				_hitContainer["eyeBeam"].visible = false;
				_hitContainer["pyramid"].visible = false;
				_hitContainer["darkness"].visible = false;
				Dialog(emcee.get(Dialog)).setCurrentById("after_contest");
				Dialog(superhero.get(Dialog)).setCurrentById("after_contest");
				Dialog(viking.get(Dialog)).setCurrentById("after_contest");
				Dialog(hippie.get(Dialog)).setCurrentById("after_contest");
				this.removeEntity(omegon);
				this.removeEntity(contestant1);
				this.removeEntity(contestant2);
				this.removeEntity(henchbot);
			}else if(this.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.OMEGON_COSTUME )){
				if(SkinUtils.getLook(player, false).getValue(SkinUtils.FACIAL) == "poptropicon_omegon" && 
					SkinUtils.getLook(player, false).getValue(SkinUtils.MARKS) == "poptropicon_omegon2" && 
					SkinUtils.getLook(player, false).getValue(SkinUtils.OVERSHIRT) == "poptropicon_omegon2" && 
					SkinUtils.getLook(player, false).getValue(SkinUtils.PACK) == "poptropicon_omegon2" ||
					this.shellApi.checkEvent( _events.PUT_ON_COSTUME )) {
					SceneUtil.lockInput(this, true);
					emcee.get(Dialog).faceSpeaker = false;
					omegon.get(Dialog).faceSpeaker = false;
					setupPanTarget();
					setupPlayerLook();	
					superhero.get(Spatial).rotation = -20;
					
					this.removeEntity(hippie);
					this.removeEntity(viking);
					
					var clip:MovieClip = _hitContainer["darkness"];
					_hitContainer.addChildAt(clip, 0);
					_hitContainer.addChildAt(superhero.get(Display).displayObject, 0);
					
					//hippie.get(Spatial).x = superhero.get(Spatial).x - 60;
					//viking.get(Spatial).x = superhero.get(Spatial).x - 80;
					//viking.get(Spatial).y -= 20;
					//CharUtils.setDirection(hippie, true);
					//CharUtils.setDirection(viking, true);
					
					//DisplayUtils.moveToTop(hippie.get(Display).displayObject);
					
					//var clip:MovieClip = _hitContainer["darkness"];
					//var container:DisplayObjectContainer = super.getEntityById("foreground").get(Display).displayObject;
					//container.addChild(clip);
					super.getEntityById("foreground").get(Display).visible = false;
					
				}else{
					this.removeEntity(omegon);
					this.removeEntity(contestant1);
					this.removeEntity(contestant2);
					this.removeEntity(henchbot);
					Dialog(emcee.get(Dialog)).setCurrentById("get_ready");
					Dialog(emcee.get(Dialog)).start.add(checkDialogStart);
					_hitContainer["eyeBeam"].visible = false;
					_hitContainer["pyramid"].visible = false;
					_hitContainer["darkness"].visible = false;
				}
			}else{
				_hitContainer["eyeBeam"].visible = false;
				_hitContainer["pyramid"].visible = false;
				_hitContainer["darkness"].visible = false;
			}
			
			if( !this.checkHasCard(_events.TEEN_ARACHNID) )
			{
				setupCard();
			}
			else
			{
				_hitContainer.removeChild( _hitContainer["card"] );
				super.removeEntity(getEntityById("cardInteraction"));
			}
			
			setupChairs();
			setupTeleporter();
			setupPushBoxes();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(923, 115));	

			super.loaded();
		}
		
		private function checkDialogStart(dialogData:DialogData):void
		{
			SceneUtil.lockInput(this, true);
			emcee.get(Interaction).lock = true;
		}
		
		private function setupChairs():void {
			var clip:MovieClip = _hitContainer["chairs"];
			
			chairs = EntityUtils.createSpatialEntity(this, _hitContainer["chairs"]);
			BitmapUtils.createBitmap(chairs.get(Display).displayObject);
			
			if( PlatformUtils.isMobileOS) {
				chairs.get(Spatial).x = 277;
				
				var doorCommon:Entity = this.getEntityById("doorCommon");
				if(doorCommon)
				{
					var doorCommonInteraction:SceneInteraction = doorCommon.get(SceneInteraction);
					if(doorCommonInteraction)
					{
						doorCommonInteraction.reached.removeAll();
						doorCommonInteraction.reached.add(clickClosedDoor);
					}	
				}
			}
		}
		
		private function clickClosedDoor(...p):void {
			Dialog(player.get(Dialog)).sayById("locked");
		}
		
		private function setupGlassBreak():void {
			var shardAsset:MovieClip = super.getAsset( "shard.swf") as MovieClip; 
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(shardAsset);
			mirrorEmitter = new MirrorBreak();
			mirrorEmitter.init( bitmapData );
			
			mirrorTarget = new Entity();
			mirrorTarget.add(new Spatial());
			mirrorTarget.get(Spatial).x = 1498;
			mirrorTarget.get(Spatial).y = 385;
			
			mirrorEmitterEntity = EmitterCreator.create( this, super._hitContainer, mirrorEmitter, 0, 0, player, "mEmitterEntity" );
			mirrorEmitterEntity.get(Spatial).x = 1498;
			mirrorEmitterEntity.get(Spatial).y = 346;
			
			mirrorEmitter.start();
			player.get(Spatial).x = 1500;
			player.get(Spatial).y = 480;
			
			shellApi.triggerEvent("break_glass");
		}
		
		private function setupPushBoxes():void
		{
			var sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
			
			super.addSystem(new SceneObjectHitRectSystem());
			
			super.player.add(new SceneObjectCollider());
			super.player.add(new RectangularCollider());
			super.player.add( new Mass(100) );
			
			var box:Entity;
			var clip:MovieClip;
			var bounds:Rectangle;
			for (var i:int = 0; _hitContainer["box"+i] != null; i++) 
			{
				clip = _hitContainer["bounds"+i];
				//bounds = new Rectangle(clip.x,clip.y,clip.width,clip.height);
				_hitContainer.removeChild(clip);
				clip = _hitContainer["box"+i] ;
				clip.mouseEnabled = true;
				box = sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x, clip.y,null,null,null,this,null,null,400);
				SceneObjectMotion(box.get(SceneObjectMotion)).rotateByPlatform = false;
				box.add(new Id("box"+i));
				box.add(new WallCollider());
				// box sounds
				var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
				audioGroup.addAudioToEntity(box, "box");
				new HitCreator().addHitSoundsToEntity(box,audioGroup.audioData,shellApi,"box");
			}
			
			
			
			
			if(superhero.get(Display).container.getChildIndex(superhero.get(Display).displayObject) > superhero.get(Display).container.getChildIndex(box.get(Display).displayObject)){
				superhero.get(Display).container.swapChildren(superhero.get(Display).displayObject, box.get(Display).displayObject);
			}
			if(this.getEntityById("viking")){
				if(viking.get(Display).container.getChildIndex(viking.get(Display).displayObject) > viking.get(Display).container.getChildIndex(box.get(Display).displayObject)){
					viking.get(Display).container.swapChildren(viking.get(Display).displayObject, box.get(Display).displayObject);
				}
			}
			if(this.getEntityById("hippie")){
				if(hippie.get(Display).container.getChildIndex(hippie.get(Display).displayObject) > hippie.get(Display).container.getChildIndex(box.get(Display).displayObject)){
					hippie.get(Display).container.swapChildren(hippie.get(Display).displayObject, box.get(Display).displayObject);
				}
			}
		}
		
		private function setFilter():void 
		{
			if(!AppConfig.mobile)
			{
				omegon.get(Display).displayObject.filters = new Array( colorGlow );
			}			
		}
		
		private function setupCard():void 
		{
			var inter:SceneInteraction = getEntityById("cardInteraction").get(SceneInteraction);
			inter.reached.addOnce(handleGetCard);
		}
		
		private function handleGetCard(...args):void 
		{
			addCardToDeck(_events.TEEN_ARACHNID);
			_hitContainer.removeChild(_hitContainer["card"]);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			if( event == "emcee_gesture" ) {
				emceeGesture();
			}else if( event == "enter_contestant_1" ) {
				CharUtils.setDirection(emcee, true);
				CharUtils.moveToTarget(contestant1, 1700, 836, false, contestant1Entered);
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, heroLine1, true));
			}else if( event == "enter_contestant_2" ) {
				CharUtils.moveToTarget(contestant2, 1600, 836, false, contestant2Entered);
			}else if( event == "enter_player" ) {
				CharUtils.moveToTarget(player, 1500, 836, false, playerEntered);
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, heroLine3, true));
			}else if( event == "enter_omegon" ) {
				cameraShake();
				oMotion = omegon.get(Motion);
				omegon.remove(Motion);
				hMotion = henchbot.get(Motion);
				henchbot.remove(Motion);
				
				super.shellApi.camera.target = teleporter.get(Spatial);
				omegon.get(Spatial).x = teleporter.get(Spatial).x - 20;
				omegon.get(Spatial).y = teleporter.get(Spatial).y + 30;
				omegon.get(Display).alpha = 0;
				henchbot.get(Spatial).x = teleporter.get(Spatial).x+20;
				henchbot.get(Spatial).y = teleporter.get(Spatial).y+15;
				henchbot.get(Display).alpha = 0;
				teleporter.get(Timeline).gotoAndPlay(1);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, transportOmegon, true));
				shellApi.triggerEvent("portal_opening");
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "energy_hum_02_loop.mp3" );
			}else if( event == "omegon_glow" ) {
				currShakeTime = 3;
				cameraShake();
				if(!AppConfig.mobile)
				{
					TweenUtils.globalTo(this, colorGlow, 3, {alpha:1, onUpdate:setFilter});
				}
				Dialog(omegon.get(Dialog)).sayById("no_mask");
			}else if( event == "omegon_attack" ) {
				CharUtils.freeze(omegon);
				DisplayUtils.moveToTop(eyeBeam.get(Display).displayObject);
				eyeBeam.get(Spatial).x = omegon.get(Spatial).x + CharUtils.getPart(omegon, CharUtils.FACIAL_PART).get(Spatial).x;
				eyeBeam.get(Spatial).y = omegon.get(Spatial).y + CharUtils.getPart(omegon, CharUtils.FACIAL_PART).get(Spatial).y;
				eyeBeam.get(Display).alpha = .2;
				eyeBeam.get(Tween).to(eyeBeam.get(Display), .01, { alpha:.9, repeat:300 });
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "energy_hum_01_loop.mp3" );
				Dialog(emcee.get(Dialog)).sayById("ahh");
				Dialog(superhero.get(Dialog)).sayById("ahh");
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, getMedal, true));
				shellApi.triggerEvent("surprised");
			}else if( event == "shake3" ) {
				currShakeTime = 3;
				cameraShake();
			}else if( event == "shake4" ) {
				currShakeTime = 4;
				cameraShake();
			}else if( event == "get_ready" ) {
				SceneUtil.lockInput(this, true);
				Dialog(player.get(Dialog)).sayById("get_ready");
			}else if( event == "run_off" ) {
				this.shellApi.completeEvent( _events.PUT_ON_COSTUME );
				CharUtils.moveToTarget(player, 2245, 947, false, removeNPCs);
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, setupForContest, true));
			}
			
		}
		
		private function setupForContest():void {
			this.shellApi.loadScene(Theater);
		}
		
		private function heroLine1():void {
			Dialog(superhero.get(Dialog)).sayById("hehheh");
			//CharUtils.setAnim(hippie, Laugh, false);
			//CharUtils.setAnim(viking, Laugh, false);
		}
		private function heroLine2():void {
			Dialog(superhero.get(Dialog)).sayById("hmm");
		}
		private function heroLine3():void {
			Dialog(superhero.get(Dialog)).sayById("ooh");
			//CharUtils.setAnim(viking, Salute, false);
		}
		
		private function transportOmegon():void {
			var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
			_transportGroup.transportIn( omegon, false, .1 );
			_transportGroup.transportIn( henchbot, false, 1 );
			SceneUtil.addTimedEvent(this, new TimedEvent(3.5, 1, dropOmegon, true));
			SceneUtil.addTimedEvent(this, new TimedEvent(4.5, 1, dropHenchbot, true));
		}
		
		private function dropOmegon():void {
			omegon.add(oMotion);
			super.shellApi.camera.target = panTarget.get(Spatial);
			pyramid.get(Tween).to(pyramid.get(Display), .3, { alpha:1, ease:Sine.easeInOut });
			shellApi.triggerEvent("surprised");
		}
		
		private function dropHenchbot():void {
			henchbot.add(hMotion);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, chaseContestants, true));
			Dialog(contestant1.get(Dialog)).sayById("ahh");
			Dialog(contestant2.get(Dialog)).sayById("ahh");
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "energy_hum_02_loop.mp3" );
		}
		
		private function chaseContestants():void {
			SceneUtil.addTimedEvent(this, new TimedEvent(.3, 1, contestantsRun, true));
			CharUtils.moveToTarget(henchbot, 1920, 836, false, removeNPCs);
		}
		
		private function contestantsRun():void {
			CharUtils.moveToTarget(contestant1, 1920, 836, false);
			CharUtils.moveToTarget(contestant2, 1920, 836, false);
			//CharUtils.moveToTarget(viking, 200, viking.get(Spatial).y, false);
			//CharUtils.moveToTarget(hippie, 200, hippie.get(Spatial).y, false);
		}
		
		private function removeNPCs(entity:Entity):void {
			removeEntity(contestant1);
			removeEntity(contestant2);
			removeEntity(henchbot);
			Dialog(emcee.get(Dialog)).sayById("amazing");
		}
		
		private function setupPanTarget():void {
			panTarget = EntityUtils.createSpatialEntity(this, _hitContainer["panTarget"]);
			panTarget.get(Display).alpha = 0;
			super.shellApi.camera.target = panTarget.get(Spatial);
			//setup npcs with states so they'll fall
			var states:Vector.<Class> = new <Class>[ FallState, JumpState, LandState, RunState, SkidState, StandState, WalkState ]; 
			CharacterGroup(super.getGroupById( CharacterGroup.GROUP_ID )).addFSM( omegon, true, states );	
			CharacterGroup(super.getGroupById( CharacterGroup.GROUP_ID )).addFSM( henchbot, true, states );	
			
			Sleep(omegon.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(omegon.get(Sleep)).sleeping = false;
			Sleep(henchbot.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(henchbot.get(Sleep)).sleeping = false;
			
			runContest();
		}
		
		private function runContest():void {
			Dialog(emcee.get(Dialog)).sayById("welcome");
			shellApi.triggerEvent("cheer2");
		}
		
		private function contestant1Entered(entity:Entity):void {
			Dialog(emcee.get(Dialog)).sayById("terrible");
			shellApi.triggerEvent("laugh2");
		}
		
		private function contestant2Entered(entity:Entity):void {
			CharUtils.setAnim(contestant2, Trip);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, runUnfortunate, true));
			SceneUtil.addTimedEvent(this, new TimedEvent(.7, 1, crowdLaugh, true));
		}
		
		private function crowdLaugh():void {
			shellApi.triggerEvent("laugh");
		}
		
		private function runUnfortunate():void {
			Dialog(emcee.get(Dialog)).sayById("unfortunate");
		}
		
		private function playerEntered(entity:Entity):void {
			CharUtils.setDirection(player, false);
			Dialog(emcee.get(Dialog)).sayById("pretty_good");
			shellApi.triggerEvent("cheer1");
		}
		
		private function runOpeningDialog():void {
			Dialog(emcee.get(Dialog)).sayById("dramatic");	
		}
		
		private function cameraShake():Boolean
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion= cameraEntity.get(WaveMotion);			
			
			if(waveMotion != null)
			{
				AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "earthquake_02_loop.mp3" );
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
				return(false);
			}
			else
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "earthquake_02_loop.mp3" );
				waveMotion = new WaveMotion();
				SceneUtil.addTimedEvent(this, new TimedEvent(currShakeTime, 1, cameraShake, true));
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 1;
			waveMotionData.rate = 1;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
			
			return(true);
		}
		
		private function setupPlayerLook():void 
		{
			// create a new LookData class
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, "0xfee0d8" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.HAIR, "empty" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, "0x72472b" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "empty" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM2, "empty" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.FACIAL, "poptropicon_omegon" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.MARKS, "poptropicon_omegon2" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, "poptropicon_omegon2" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.PACK, "poptropicon_omegon2" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.SHIRT, "empty" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, "empty" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.PANTS, "miner2" ) );			
			lookData.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, "squint" ) );
			
			SkinUtils.applyLook( player, lookData, false );
			
			player.get(Spatial).x = 1920;
			player.get(Spatial).y = 630;
		}
		
		private function setupTeleporter():void {
			var clip:MovieClip = _hitContainer["teleporter"];
			BitmapUtils.convertContainer(clip);
			
			teleporter = new Entity();
			teleporter = TimelineUtils.convertClip( clip, this, teleporter );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			teleporter.add(spatial);
			teleporter.add(new Display(clip));
			teleporter.add(new Id("show"));
			
			super.addEntity(teleporter);
			teleporter.get(Timeline).gotoAndStop(0);
		}
		
		private function emceeGesture():void {
			CharUtils.setAnim(emcee, Salute, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(.7, 1, showStartPopup, true));
		}
		
		private function showStartPopup():void
		{
			SceneUtil.lockInput(this, false);
			var startPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			startPopup.updateText("Win the costume contest!", "Start");
			startPopup.configData("startPopup.swf", "scenes/con2/shared/popups/");
			startPopup.popupRemoved.addOnce(startPopupClosed);
			addChildGroup(startPopup);
		}
		
		private function startPopupClosed():void
		{
			shellApi.completeEvent(_events.SAW_START_POPUP);
			Dialog(emcee.get(Dialog)).sayById("whoever");
		}
		
		private function getMedal():void {
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "energy_hum_01_loop.mp3" );
			if ( !shellApi.checkEvent( GameEvent.HAS_ITEM + _events.MEDAL_CON2 )) {
				shellApi.getItem( _events.MEDAL_CON2, null, true );
				//shellApi.completedIsland();
				var showItem:ShowItem = getGroupById( ShowItem.GROUP_ID ) as ShowItem;
				
				showItem.transitionComplete.addOnce( medallionReceived );
			} else {
				medallionReceived();
			}
		}

		private function medallionReceived():void
		{
			shellApi.completedIsland('', showFinalPopup);
		}
		
		private function showFinalPopup(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false);
			//addChildGroup(new EndingPopup(overlayContainer));
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}
		
//		private function finalPopupClosed():void
//		{
//			shellApi.loadScene( Map, NaN, NaN, null, NaN, 1 );
//		}
	}
}
