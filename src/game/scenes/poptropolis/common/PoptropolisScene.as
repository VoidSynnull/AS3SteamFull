package game.scenes.poptropolis.common
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.profile.TribeData;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.poptropolis.coliseum.Coliseum;
	import game.systems.SystemPriorities;
	import game.systems.TimerSystem;
	import game.systems.audio.HitAudioSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.EdgeSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayPositionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.Utils;

	public class PoptropolisScene  extends PlatformerGameScene
	{
		private const EXIT_PRACTICE:String = "EXIT PRACTICE";
		private const STOP_GAME:String = "STOP GAME";
		
		protected var _instructionsPopup:PoptropolisInstructions;
		protected var _practice:Boolean;
		protected var _exitBtn:Entity;
		
		private var _debugClip:DisplayObjectContainer;
		private var _debugDotIndex:int= 0 
		
		protected var _playerDummy:Entity;
		protected var _lastMouseDownTime:uint;
		
		public function PoptropolisScene()
		{
		}
		
		// Can't find a good way to reuse this popup. Maybe it doesn't matter?
		public function get lastMouseDownTime():uint
		{
			return _lastMouseDownTime;
		}
		
		protected function openInstructionsPopup():void
		{
			_instructionsPopup = super.addChildGroup(new PoptropolisInstructions(super.overlayContainer)) as PoptropolisInstructions;
			_instructionsPopup.startClicked.addOnce(onStartClicked)
			_instructionsPopup.practiceClicked.addOnce(onPracticeClicked)
			_instructionsPopup.debugClicked.addOnce(onDebugClicked)
				
			if( _exitBtn ) { showExitBtn( false ); }
		}
		
		// To be overridden
		protected function onStartClicked (): void {
		}
		
		// To be overridden
		protected function onPracticeClicked (): void {
			
		}
		
		// To be overridden
		protected function onDebugClicked (): void {
			
		}
		
		// To be overridden
		protected function exitPractice(): void 
		{
		}
		
		// To be overridden
		protected function exitGame(): void 
		{
		}
		
		//////////////////////////////// EXIT BUTTON ////////////////////////////////
		
		// NOTE :: ExitBtn setup is giving me grief an dis still unstable, avoid use until I've fixed it. - Bard
		protected function createExitBtn( isVisible:Boolean = true, displayPositions:String = "bottomRight", padding:int = 10 ): void 
		{
			super.shellApi.loadFile( super.shellApi.assetPrefix + "scenes/poptropolis/shared/poptropolis_btn.swf", onExitBtnLoaded, isVisible, displayPositions, padding ); 
		}
		
		public function showExitBtn( isVisible:Boolean = true ):void 
		{
			var display:Display = _exitBtn.get(Display);
			display.visible = isVisible;
			MovieClip(display.displayObject).text_mc.tf.text = ( _practice ) ? EXIT_PRACTICE : STOP_GAME;
		}
		
		private function onExitBtnLoaded ( displayObject:DisplayObjectContainer, isVisible:Boolean = true, displayPositions:String = "bottomRight", padding:int = 20 ):void 
		{
			var btnClip:MovieClip = MovieClip(displayObject).content as MovieClip;
			btnClip.text_mc.tf = TextUtils.refreshText( btnClip.text_mc.tf, "Diogenes" );
			btnClip.mouseChildren = false;
			// position button prior to making button ( isStatic within createButtonEntity causes button position not correlate to Spatial)
			DisplayPositionUtils.position( btnClip, displayPositions, shellApi.viewportWidth, shellApi.viewportHeight, padding, padding );
			_exitBtn = ButtonCreator.createButtonEntity( btnClip, this, this.exitButtonClicked, this.overlayContainer, null, ToolTipType.CLICK, false  ); 

			Display( _exitBtn.get(Display) ).visible = isVisible;
		}
		
		private function exitButtonClicked ( btnEntity:Entity = null ):void 
		{
			if( _practice )
			{
				this.exitPractice();
			}
			else
			{
				this.exitGame();
			}
		}
		
		//////////////////////////////// HELPERS ////////////////////////////////
		
		protected  function addMotion (entity:Entity):void 
		{
			var motion:Motion = entity.get( Motion )
			if ( !motion )
			{
				motion = new Motion();
				entity.add( motion );
			}
			motion.friction 	= new Point(0, 0);
			motion.maxVelocity 	= new Point(1000,1000);
			motion.minVelocity 	= new Point(0, 0);
			entity.add( motion );
		}
		
		protected function playSoundEffect(str:String,baseVolume:Number = 1,loop:Boolean = false):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + str +".mp3",baseVolume,loop);
		}
		
		protected function stopEntityMotion(e:Entity):void 
		{
			var motion:Motion = Motion (e.get(Motion))
			motion.acceleration.x = 0	
			motion.acceleration.y = 0	
			motion.velocity.x = 0	
			motion.velocity.y = 0
		}
		
		protected function setupSpectators():void
		{
			var emotions:Array = ["cheer", "ooh", "angry", "sad", "clap"];
			
			var i:int = 1
			while (this._hitContainer["crowd" + i])
			{
				var clip:MovieClip = this._hitContainer["crowd" + i];
				clip.gotoAndStop(1);

				var skin:int = Utils.randInRange(1, 3);
				var integer:int = Utils.randInRange(0, emotions.length - 1);
				var emotion:String = emotions[integer];
				
				clip["head"]["expression"].gotoAndStop(integer + 1);
				clip["body"]["shirt"].gotoAndStop(Utils.randInRange(1, 5));
				clip["hair"].gotoAndStop(Utils.randInRange(1, 5));
				
				//Skin Color
				clip["feet"].gotoAndStop(skin);
				clip["hand1"].gotoAndStop(skin);
				clip["hand2"].gotoAndStop(skin);
				clip["head"]["head"].gotoAndStop(skin);
				clip["head"]["expression"]["eyeLids"].gotoAndStop(skin);
				
				var spectator:Entity = TimelineUtils.convertClip(clip, this);
				changeExpression(spectator, emotions, skin);
				i++
			}
		}
		
		protected function changeExpression(spectator:Entity, emotions:Array, skin:int):void
		{
			var integer:int = Utils.randInRange(0, emotions.length - 1);
			var emotion:String = emotions[integer];
			
			var timeline:Timeline = spectator.get(Timeline);
			timeline.gotoAndPlay(emotion);
			
			var clip:MovieClip = TimelineClip(spectator.get(TimelineClip)).mc;
			clip["head"]["expression"].gotoAndStop(integer + 1);
			clip["head"]["expression"]["eyeLids"].gotoAndStop(skin);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(Utils.randInRange(4, 6), 1, Command.create(changeExpression, spectator, emotions, skin)));
		}
		
		public function updateDebugTrackCharacter(): void {
			_debugDotIndex++
			if (_debugClip.parent) _debugClip.parent.addChild(_debugClip)
			if (_debugDotIndex % 3 == 0) {
				var playerSp:Spatial = Spatial (player.get(Spatial))
				var spr:MovieClip = makeDot( 0x00FF00)
				spr.x =  playerSp.x
				spr.y =  playerSp.y
				_debugClip.addChild (spr)
				
				spr = makeDot(0x8888FF)
				spr.x =  playerSp.x
				spr.y =  750
				_debugClip.addChild (spr)
			}
		}
		
		public function set debugClip(value:DisplayObjectContainer):void
		{
			_debugClip = value;
		}
		
		private function makeDot(c:uint):MovieClip
		{
			var spr:MovieClip =	new MovieClip();
			spr.graphics.beginFill(c, 10);
			spr.graphics.lineStyle(10, c);
			spr.graphics.drawCircle(0,0,200);
			spr.graphics.endFill()
			return spr
		}
		
		public function stopAndStand():void {
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.Stand)
			var motion:Motion = Motion (_playerDummy.get(Motion))
			motion.velocity.x = 0
			motion.velocity.y = 0
			motion.acceleration.x = 0
			motion.acceleration.y = 0
		}
		
		protected function onResultsDone(matchName:String):void 
		{
			shellApi.takePhotoByEvent( String(matchName + "_completed"), endMatch );
		}
		
		protected function endMatch():void {
			shellApi.loadScene(Coliseum);
		}
		
		public function  applyTribalLook( look:LookData, tribe:TribeData = null ):void 
		{
			if( tribe == null )
			{
				tribe = TribeUtils.getTribeOfPlayer( super.shellApi);
			}
			
			if( tribe )
			{
				look.applyAspect( new LookAspectData( SkinUtils.SHIRT, tribe.jersey ) );
				look.applyAspect( new LookAspectData( SkinUtils.PANTS, tribe.jersey ) );
				look.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, SkinPart.EMPTY ) );
				look.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, SkinPart.EMPTY ) );
				look.applyAspect( new LookAspectData( SkinUtils.ITEM, SkinPart.EMPTY ) );
				look.applyAspect( new LookAspectData( SkinUtils.PACK, SkinPart.EMPTY ) );
			}
			else
			{
				trace("ERROR PoptropolisScene :: Must have a tribe selected before playing events.");
			}
		}
		
		override protected function addBaseSystems():void
		{
			// NOTE :: Commented out systems are included in PlatformGameScene, and excluded form PoptropolisScene
			//super.addSystem(new SceneInteractionSystem(), SystemPriorities.sceneInteraction);
			//super.addSystem(new TextDisplaySystem(), SystemPriorities.update);
			//super.addSystem(new DialogInteractionSystem(), SystemPriorities.lowest);
			//super.addSystem(new NavigationArrowSystem(), SystemPriorities.update);
			
			super.addSystem(new InteractionSystem(), SystemPriorities.update);	
			super.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);			
			super.addSystem(new NavigationSystem(), SystemPriorities.update);
			super.addSystem(new DestinationSystem(), SystemPriorities.update);
			super.addSystem(new TargetEntitySystem(), SystemPriorities.update);
			
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new RenderSystem(), SystemPriorities.render);
			super.addSystem(new TweenSystem(), SystemPriorities.update);
			super.addSystem(new HitAudioSystem(), SystemPriorities.updateSound)
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			
			super.addSystem(new TimerSystem(), SystemPriorities.update);
			super.addSystem(new EdgeSystem(), SystemPriorities.postRender);
		}
	}
}