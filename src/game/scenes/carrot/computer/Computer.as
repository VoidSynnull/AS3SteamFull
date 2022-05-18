package game.scenes.carrot.computer
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.carrot.CarrotEvents;
	import game.scene.template.GameScene;
	import game.scenes.carrot.robot.Robot;
	import game.util.DisplayPositionUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	public class Computer extends GameScene
	{
		public function Computer()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/computer/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			_screen = super.getAsset("computer.swf", true) as MovieClip;
			
			DisplayPositionUtils.fitToDimensions(_screen, this.shellApi.viewportWidth, this.shellApi.viewportHeight, true);
			this._screen.y = this.shellApi.viewportHeight - this._screen.height;
			
			//Remove player, since they're not needed and they're showing up behind the computer.
			this.removeEntity(this.shellApi.player);
			
			_screenLayer = _screen.content.screenLayer;
			_events = super.events as CarrotEvents;
			super.groupContainer.addChild( _screen );
			
			//put dr.Hare to sleep
			var drHare:Entity = super.getEntityById( "drHare");
			Sleep( drHare.get(Sleep) ).sleeping = true;
			Sleep( drHare.get(Sleep) ).ignoreOffscreenSleep = true;
			
			var overscreen:Entity = TimelineUtils.convertClip( _screen.content.overscreen, this );
			var timeline:Timeline = overscreen.get( Timeline );
			timeline.play();
			
			timeline.labelReached.add( screenHandler );
			
			createMessageWindow();
			_closeButton = ButtonCreator.loadCloseButton( this, this.groupContainer, onClose );
			initConsole();	// load computer console for password entry, include close button
			
			super.loaded();
		}
		
		//////////////////////////////////////////////////////////////////////
		////////////////////////// CLOSE BUTTON //////////////////////////
		//////////////////////////////////////////////////////////////////////

		private function onClose( e:Entity ):void
		{
			close();
		}
		
		//////////////////////////////////////////////////////////////////////
		////////////////////////// COMPUTER CONSOLE //////////////////////////
		//////////////////////////////////////////////////////////////////////
		

		private function initConsole():void
		{
			_console = new Console( this, _screen );
			_console.keyPress.add( keyPress );
			_console.enterPress.add( enterPress );
			_console.complete.addOnce( consoleComplete );
		}
		
		private function screenHandler( label:String ):void
		{
		}
		
		private function keyPress():void
		{
			var random:int = Math.round( Math.random() * 2 );
			switch( random )
			{
				case 0:
					super.shellApi.triggerEvent( _events.KEYBOARD_PRESS_ + 1 );
					break;
				case 1:
					super.shellApi.triggerEvent( _events.KEYBOARD_PRESS_ + 2 );
					break;
				case 2:
					super.shellApi.triggerEvent( _events.KEYBOARD_PRESS_ + 3 );
					break;
			}
		}
		
		private function enterPress():void
		{
			super.shellApi.triggerEvent( _events.ENTER_PRESS );
		}
		
		private function consoleComplete():void
		{
			_closeButton = null;
			playLaunch();
		}
		
		//////////////////////////////////////////////////////////////////////
		/////////////////////////// RABBOT LAUNCH ////////////////////////////
		//////////////////////////////////////////////////////////////////////
		
		private function playLaunch():void
		{
			super.shellApi.triggerEvent( _events.RABBOT_LAUNCH );
			var rabbotLaunch:RabbotLaunch = super.addChildGroup( new RabbotLaunch( super.groupContainer ) ) as RabbotLaunch;
			rabbotLaunch.removed.addOnce( onLaunchComplete );
		}
		
		private function onLaunchComplete( group:Group ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, startGame) )
		}
		
		//////////////////////////////////////////////////////////////////////
		/////////////////////////// ASTEROID GAME ////////////////////////////
		//////////////////////////////////////////////////////////////////////
		
		private function startGame():void
		{
			_console.destroy();

			_asteroidGame = new AsteroidGame( this, _screen );
			_asteroidGame.start();
			_asteroidGame.hitSignal.add( onHit );
			_asteroidGame.destroyed.add( destroyedRabbot );
			_asteroidGame.complete.add( onGameComplete );
		}
		
		protected function createMessageWindow( groupPrefix:String = "scenes/carrot/computer/", asset:String = "messageWindow.swf"):void
		{
			_dialogWindow = new MessageWindow( _screenLayer );
			_dialogWindow.config( null, null, false, true, true, false );
			_dialogWindow.configData( groupPrefix, asset, true, true );
			_dialogWindow.ready.addOnce( characterDialogWindowReady );
			_dialogWindow.messageComplete.add( onMessageComplete );
			
			super.addChildGroup(_dialogWindow);
		}
		
		protected function characterDialogWindowReady( charDialog:MessageWindow ):void
		{
			// adjust character
			charDialog.adjustChar( "drHare", _dialogWindow.screen.content.headContainer, new Point(0, 0), .35 );
			charDialog.charEntity.get( Display ).visible = false;
			
			// assign textfield
			charDialog.textField = TextUtils.refreshText( charDialog.screen.content.tf );	
			
			charDialog.textField.embedFonts = true;
			charDialog.textField.defaultTextFormat = new TextFormat("CreativeBlock BB", 16, 0x000000 );
		}
		
		private function onHit( hitCount:int ):void
		{
			super.shellApi.triggerEvent( _events.RABBOT_HIT );
			super.shellApi.triggerEvent( _events.DR_HARE_TALK );
			_dialogWindow.playMessage( "RabbotHit" + hitCount, true, true );	// play message for hit
		}
		
		private function destroyedRabbot():void
		{
			shellApi.triggerEvent( _events.DESTROYED_RABBOT, true );
		}
		
		private function onMessageComplete():void
		{
			_asteroidGame.unpause();
		}
		
		public function onGameComplete():void
		{
			close();
		}
		
		public function close():void
		{
			super.shellApi.loadScene( Robot, 1900, 1000, "left" );
		}
		
		private const HIT_MAX:int = 4;
		
		private var _events:CarrotEvents;
		private var _closeButton:Entity;
		private var _console:Console;
		private var _asteroidGame:AsteroidGame;
		private var _dialogWindow:MessageWindow;
		private var _screen:MovieClip;
		private var _screenLayer:MovieClip;
	}
}