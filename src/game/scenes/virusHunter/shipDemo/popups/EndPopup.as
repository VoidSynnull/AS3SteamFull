package game.scenes.virusHunter.shipDemo.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.systems.TweenSystem;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ui.TransitionData;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.map.map.Map;
	import game.scenes.virusHunter.shipDemo.components.Current;
	import game.scenes.virusHunter.shipDemo.systems.CurrentSystem;
	import game.ui.elements.BasicButton;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class EndPopup extends Popup
	{
		public function EndPopup(container:DisplayObjectContainer=null, win:Boolean = false, score:Number = 0, wave:Number = 1)
		{
			super(container);
			this.playAgainClicked = new Signal();
			this.closePanel = new Signal();
			this.loadScreen = new Signal();
			this.screenStatic = new Signal();
			this.buttonClick = new Signal();
			this.beatGame = new Signal();
			
			this._quitClicked = new Signal();
	
			_win = win;
			_score = score;
			_wave = wave;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			
			super.transitionIn.startPos = new Point( 0, 0 );
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.addSystem( new TweenSystem() );
			super.addSystem( new CurrentSystem());
			
			super.darkenBackground = false;
			super.groupPrefix = "scenes/virusHunter/shipDemo/popups/end/";
			super.init( container );
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("end.swf", GameScene.NPCS_FILE_NAME, GameScene.DIALOG_FILE_NAME ));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("end.swf", true) as MovieClip;
			super.loaded();
			
			var retryButton:BasicButton;
			var quitButton:BasicButton;
			var victory:Entity;
			var floatingBackground:Entity;
			var floatingInterface:Entity;
			var id:Id;
			var display:Display;
			var timeline:Timeline;
			
			var ship:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.ship );
			id = new Id( "ship" );
			ship.add( id );
			display = ship.get( Display );
			display.visible = false;
			
			retryButton = ButtonCreator.createBasicButton( super.screen.content.button4, [ InteractionCreator.CLICK ]);
			retryButton.click.add( this.playAgainClicked.dispatch );
			_retryButton = EntityUtils.createMovingEntity( this, super.screen.content.button4 );
			
			display = _retryButton.get( Display );
			display.alpha = 0;
			display.visible = false;
			
			quitButton = ButtonCreator.createBasicButton( super.screen.content.button3, [ InteractionCreator.CLICK ]);
			quitButton.click.add( this._quitClicked.dispatch );
			this._quitClicked.addOnce( quitButtonClicked );
			_quitButton = EntityUtils.createMovingEntity( this, super.screen.content.button3 );
			
			display = _quitButton.get( Display );
			display.alpha = 0;
			display.visible = false;
			
			victory = EntityUtils.createSpatialEntity( this, super.screen.content.victory );
			id = new Id( "victory" );
			victory.add( id );
			display = victory.get( Display );
			display.alpha = 0;
			display.visible = false;
			
			
			floatingBackground = EntityUtils.createSpatialEntity( this, super.screen.content.floatingInterfaceBackground );
			id = new Id( "floatingBackground" );
			floatingBackground.add( id );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( floatingBackground )), this, floatingBackground );
			timeline = floatingBackground.get( Timeline );
			timeline.paused = true;
			display = floatingBackground.get( Display );
			display.alpha = 0;
			
			floatingInterface = EntityUtils.createSpatialEntity( this, super.screen.content.floatingInterface );
			id = new Id( "floatingInterface" );
			floatingInterface.add( id );

			display = floatingInterface.get( Display );
			display.alpha = 0;
			
			var resultsIcon:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.floatingInterface.resultsIcon );
			id = new Id( "resultsIcon" );
			resultsIcon.add( id );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( resultsIcon )), this, resultsIcon );
			
			var redLight:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.leftPanel.redLight );
			id = new Id( "redLight" );
			redLight.add( id );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( redLight )), this, redLight );
			timeline = redLight.get( Timeline );
			timeline.gotoAndStop( 1 );
			
			var greenLight:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.leftPanel.greenLight );
			id = new Id( "greenLight" );
			greenLight.add( id );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( greenLight )), this, greenLight );
			timeline = greenLight.get( Timeline );
			timeline.gotoAndStop( 1 );
			
			this._scoreDisplay = super.screen.content.floatingInterface.scoreDisplay;
			this._waveDisplay = super.screen.content.floatingInterface.waveDisplay;
			_scoreDisplay.text = _score.toString();
			_waveDisplay.text = _wave.toString();
			
			var current:Current = new Current( 240, 240, 230, 40, 640, 50, 80, 1, 0x35A5FF );
			var electricity:Entity = EntityUtils.createSpatialEntity( this, new Sprite(), super.screen.content.leftPanel.charCurrentContainer );
			electricity.add( current );
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.screen, super.getData(GameScene.NPCS_FILE_NAME), allCharactersLoaded);
			
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			characterDialogGroup.setupGroup(this, super.getData(GameScene.DIALOG_FILE_NAME), super.screen);
		}
		
		private function allCharactersLoaded():void
		{
			var drLang:Entity = super.getEntityById("drLang");
			
			CharUtils.setScale( drLang, .8 );
			
			var clip:MovieClip = MovieClip(super.screen.content).getChildByName( "charHolder" ) as MovieClip;
			Display( drLang.get( Display )).setContainer( clip );
			var dialog:Dialog;
			var children:Children;
			var edge:Edge;
			var entity:Entity;
			
			dialog = drLang.get( Dialog );
			edge = drLang.get( Edge );
			dialog.dialogPositionPercents = new Point( 1, 1 );	
			dialog.container = this.screen;
			edge.unscaled.setTo(120, 0, 120, 150);
			children = drLang.get( Children );
			entity = children.children[ 0 ];
			super.removeEntity( entity );
			
			super.open();
			
			var tween:Tween;
			var display:Display;
			var spatial:Spatial;
			var sleep:Sleep;
			var timeline:Timeline;
			var id:Id;
			
			var leftPanel:Entity = EntityUtils.createMovingEntity( this, super.screen.content.leftPanel );
			tween = new Tween();
			id = new Id( "leftPanel" );
			spatial = leftPanel.get( Spatial );
			tween.to( spatial, 2, { x : 174, onComplete : loadResults });
			leftPanel.add( tween ).add( id );
			closePanel.dispatch();
			
			var rightPanel:Entity = EntityUtils.createMovingEntity( this, super.screen.content.rightPanel );
			tween = new Tween();
			id = new Id( "rightPanel" );
			spatial = rightPanel.get( Spatial );
			tween.to( spatial, 2, { x : 1219 });
			rightPanel.add( tween ).add( id );
			
			var charBackground:Entity = EntityUtils.createMovingEntity( this, super.screen.content.drLangScreen );
			tween = new Tween();
			id = new Id( "charBackground" );
			spatial = charBackground.get( Spatial );
			tween.to( spatial, 2, { x : 26.45 });
			charBackground.add( tween ).add( id );
			
			var charHolder:Entity = EntityUtils.createMovingEntity( this, super.screen.content.charHolder );
			tween = new Tween();
			id = new Id( "charHolder" );
			spatial = charHolder.get( Spatial );
			tween.to( spatial, 2, { x : 0 });
			charHolder.add( tween ).add( id );
			
			var light:Entity;
			if( _win )
			{
				light = super.getEntityById( "greenLight" );
				timeline = light.get( Timeline );
				timeline.paused = true;
				timeline.gotoAndStop( 0 );
			}
			else
			{
				light = super.getEntityById( "redLight" );
				timeline = light.get( Timeline );
				timeline.paused = true;
				timeline.gotoAndStop( 0 );
				
				var ship:Entity = super.getEntityById( "ship" );
				display = ship.get( Display );
				display.visible = true;
			}
			
//			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, startDialog));
		}
		
		private function loadResults():void
		{
			screenStatic.dispatch();
			var floatingBackground:Entity;
			
			var tween:Tween;
			var display:Display;
			var timeline:Timeline;
			
			floatingBackground = super.getEntityById( "floatingBackground" );
			display = floatingBackground.get( Display );
			display.alpha = 1;
			timeline = floatingBackground.get( Timeline );
			timeline.labelReached.add( backgroundHandler );
			
			timeline.paused = false;
			timeline.gotoAndPlay( 1 );	
			loadScreen.dispatch();
		}
		
		private function backgroundHandler( label:String ):void
		{
			var floatingBackground:Entity = super.getEntityById( "floatingBackground" );
			var floatingInterface:Entity = super.getEntityById( "floatingInterface" );
			
			var timeline:Timeline = floatingBackground.get( Timeline );
			var display:Display = floatingInterface.get( Display );
			
			var tween:Tween;
			
			switch( label )
			{
				case "stopMiddle":
				if( !_backgroundOpen )
				{	
					tween = new Tween();
					tween.to( display, 2, { alpha : 1, onComplete : startDialog });
					floatingInterface.add( tween );
					
					timeline.paused = true;
					_backgroundOpen = true;
				}
			}
		}
		
		private function quitButtonClicked( ...args ):void
		{
			buttonClick.dispatch();
			shellApi.loadScene(Map);
		}
		
		private function startDialog():void
		{
			SceneUtil.lockInput( this, false );
			var tween:Tween;
			var display:Display;
			
			tween = new Tween();
			display = _retryButton.get( Display );
			display.visible = true;
			tween.to( display, 2, { alpha : 1 });
			_retryButton.add( tween );
			
			tween = new Tween();
			display = _quitButton.get( Display );
			display.visible = true;
			tween.to( display, 2, { alpha : 1, onComplete : addTooltips });
			_quitButton.add( tween );
			
			if( _win )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( 5, 1, showVictory ));
				beatGame.dispatch();
			}
			else
			{
				super.shellApi.triggerEvent("tryagain");
			}
		}
		
		private function addTooltips():void
		{
			ToolTipCreator.addToEntity( _quitButton );
			ToolTipCreator.addToEntity( _retryButton );
		}
		
		private function showVictory():void
		{
			var display:Display;
			var tween:Tween;
			super.shellApi.triggerEvent("congrats");
			var victory:Entity = super.getEntityById( "victory" );
			display = victory.get( Display );
			display.visible = true;
			tween = new Tween();
			
			tween.to( display, 2, { alpha : 1 });
			victory.add( tween );
		}
		
		public var playAgainClicked:Signal;
		public var buttonClick:Signal;
		public var closePanel:Signal;
		public var loadScreen:Signal;
		public var screenStatic:Signal;
		public var beatGame:Signal;
		
		private var _win:Boolean;
		private var _backgroundOpen:Boolean = false;
		
		private var _score:Number = 0;
		private var _wave:Number = 1;
		
		private var _scoreDisplay:TextField;
		private var _waveDisplay:TextField;
		
		private var _quitClicked:Signal;
		private var _retryButton:Entity;
		private var _quitButton:Entity;
	}
}