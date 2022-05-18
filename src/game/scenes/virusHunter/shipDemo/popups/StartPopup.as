package game.scenes.virusHunter.shipDemo.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
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
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.virusHunter.shipDemo.components.Current;
	import game.scenes.virusHunter.shipDemo.systems.CurrentSystem;
	import game.ui.elements.BasicButton;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class StartPopup extends Popup
	{
		public function StartPopup( container:DisplayObjectContainer=null )
		{
			super(container);
			
			this._startClicked = new Signal();
			this._launchClicked = new Signal();
			this._moreInfoClicked = new Signal();
			
			this.startSignal = new Signal();
			
			this.buttonClick = new Signal();
			this.openPanel = new Signal();
			this.panelClang = new Signal();
			this.closePanel = new Signal();
			this.screenStatic = new Signal();
			this.loadScreen = new Signal();
			this.switchLights = new Signal();
	//		this.buttonPressed = new Signal();
			
			
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
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
			super.groupPrefix = "scenes/virusHunter/shipDemo/popups/start/";
			super.init(container);
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce( loaded );
			super.loadFiles( new Array( "start.swf", GameScene.NPCS_FILE_NAME, GameScene.DIALOG_FILE_NAME ));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset( "start.swf", true ) as MovieClip;	
			
			var startButton:BasicButton;
			var launchButton:BasicButton;
			var moreInfo1Button:BasicButton;
			var moreInfo2Button:BasicButton;
			var floatingBackground:Entity;
			var floatingInterface:Entity;
			var id:Id;
			var display:Display;
			var timeline:Timeline;
			
			startButton = ButtonCreator.createBasicButton( super.screen.content.button1, [ InteractionCreator.CLICK ]);
			startButton.click.add( this._startClicked.dispatch );
			this._startClicked.addOnce( startButtonClicked );
			_startButton = EntityUtils.createMovingEntity( this, super.screen.content.button1 );
			
			display = _startButton.get( Display );
			display.alpha = 0;
			display.visible = false;
			
			launchButton = ButtonCreator.createBasicButton( super.screen.content.button2, [ InteractionCreator.CLICK ]);
			launchButton.click.add( this._launchClicked.dispatch );
			this._launchClicked.addOnce( launchButtonClicked );
			_launchButton = EntityUtils.createMovingEntity( this, super.screen.content.button2 );
			
			
			display = _launchButton.get( Display );
			display.alpha = 0;
			display.visible = false;
			
			moreInfo1Button = ButtonCreator.createBasicButton( super.screen.content.moreInfo1, [ InteractionCreator.CLICK ]);
			moreInfo1Button.click.add( this._moreInfoClicked.dispatch );
			this._moreInfoClicked.add( launchWebSite );
			moreInfo2Button = ButtonCreator.createBasicButton( super.screen.content.moreInfo2, [ InteractionCreator.CLICK ]);
			moreInfo2Button.click.add( this._moreInfoClicked.dispatch );
			this._moreInfoClicked.add( launchWebSite );
						
			_moreInfo1Button = EntityUtils.createSpatialEntity( this, super.screen.content.moreInfo1 );
			_moreInfo2Button = EntityUtils.createSpatialEntity( this, super.screen.content.moreInfo2 );
			//moreInfoButton2 = ButtonCreator.createBasicButton( super.screen.content.moreInfo2, [ InteractionCreator.CLICK ]);
			
			ToolTipCreator.addToEntity( _moreInfo1Button );
			ToolTipCreator.addToEntity( _moreInfo2Button );
			
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
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( floatingInterface )), this, floatingInterface );
			timeline = floatingInterface.get( Timeline );
			timeline.gotoAndStop( 0 );
			display = floatingInterface.get( Display );
			display.alpha = 0;
					
			var elipsee1:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.floatingInterface.elipsee1 );
			id = new Id( "elipsee1" );
			elipsee1.add( id );
			display = elipsee1.get( Display );
			display.alpha = 0;
			
			var elipsee2:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.floatingInterface.elipsee2 );
			id = new Id( "elipsee2" );
			elipsee2.add( id );
			display = elipsee2.get( Display );
			display.alpha = 0;
			
			var elipsee3:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.floatingInterface.elipsee3 );
			id = new Id( "elipsee3" );
			elipsee3.add( id );
			display = elipsee3.get( Display );
			display.alpha = 0;
			
			_trainingScreen = EntityUtils.createMovingEntity( this, super.screen.content.rightContent );
			display = _trainingScreen.get( Display );
			display.alpha = 0;
			
			var current:Current = new Current( 240, 240, 230, 40, 640, 50, 80, 1, 0x009C9C );
			var electricity:Entity = EntityUtils.createSpatialEntity( this, new Sprite(), super.screen.content.leftPanel.charCurrentContainer );
			electricity.add( current );
			
			var current2:Current = new Current( 500, 500, 630, 70, 640, 100, 150, 2, 0x009C9C ); // FF35A5FF
			var electricity2:Entity = EntityUtils.createSpatialEntity( this, new Sprite(), super.screen.content.rightContent.contentCurrentContainer );
			electricity2.add( current2 );
			
			super.addElement( startButton );
			super.addElement( launchButton );
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup( this, super.screen, super.getData(GameScene.NPCS_FILE_NAME), allCharactersLoaded );
			
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			characterDialogGroup.setupGroup( this, super.getData(GameScene.DIALOG_FILE_NAME, true), super.screen );
			
			super.loaded();
		}
		
		private function allCharactersLoaded():void
		{
			var drLang:Entity = super.getEntityById( "drLang" );
			var dialog:Dialog;
			var edge:Edge;
			var children:Children;
			var entity:Entity;
			
			CharUtils.setScale( drLang, .8 );
			
			dialog = drLang.get( Dialog );
			edge = drLang.get( Edge );
			dialog.dialogPositionPercents = new Point( 1, 1 );
			dialog.container = this.screen;
			edge.unscaled.setTo(120, 0, 120, 150);
			children = drLang.get( Children );
			entity = children.children[ 0 ];
			super.removeEntity( entity );
//			entity.add( new Edge( -80, 0, 0, 100 ));
			
			var clip:MovieClip = MovieClip(super.screen.content).getChildByName( "charHolder" ) as MovieClip;
			Display( drLang.get( Display )).setContainer( clip );
			
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
			tween.to( spatial, 2, { x : 174, onComplete : dispatchClang });
			leftPanel.add( tween ).add( id );
			closePanel.dispatch();
			
			var rightPanel:Entity = EntityUtils.createMovingEntity( this, super.screen.content.rightPanel );
			tween = new Tween();
			id = new Id( "rightPanel" );
			spatial = rightPanel.get( Spatial );
			tween.to( spatial, 2, { x : 651 });
			rightPanel.add( tween ).add( id );
		
			tween = new Tween();
			id = new Id( "trainingScreen" );
			spatial = _trainingScreen.get( Spatial );
			tween.to( spatial, 2, { x : 472 });
			_trainingScreen.add( tween ).add( id );
			
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( _trainingScreen )), this, _trainingScreen );
			timeline = _trainingScreen.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			_trainingScreen.remove( Sleep );
			
			var navHeader:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.navHeader );
			tween = new Tween();
			id = new Id( "navHeader" );
			spatial = navHeader.get( Spatial );
			tween.to( spatial, 2, { x : 415 });
			navHeader.add( tween ).add( id );
			
		//	var moreInfo1:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.moreInfo1 );
			tween = new Tween();
		//	id = new Id( "moreInfo1" );
			spatial = _moreInfo1Button.get( Spatial );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( _moreInfo1Button )), this, _moreInfo1Button );
			sleep = _moreInfo1Button.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			tween.to( spatial, 2, { x : 499 });
			_moreInfo1Button.add( tween );//.add( id );
			
		//	var moreInfo2:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.moreInfo2 );
			tween = new Tween();
		//	id = new Id( "moreInfo2" );
			spatial = _moreInfo2Button.get( Spatial );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( _moreInfo2Button )), this, _moreInfo2Button );
			sleep = _moreInfo2Button.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			tween.to( spatial, 2, { x : 837 });
			_moreInfo2Button.add( tween );//.add( id );
				
			var contentBackground:Entity = EntityUtils.createMovingEntity( this, super.screen.content.contentBackground );
			tween = new Tween();
			id = new Id( "contentBackground" );
			spatial = contentBackground.get( Spatial );
			tween.to( spatial, 2, { x : 411.55 });
			contentBackground.add( tween ).add( id );
			
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
			
			tween = new Tween();
			spatial = _startButton.get( Spatial );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( _startButton )), this, _startButton );
			sleep = _startButton.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			tween.to( spatial, 2, { x : 511 });
			_startButton.add( tween );
			
			tween = new Tween();
			spatial = _launchButton.get( Spatial );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( _launchButton )), this, _launchButton );
			sleep = _launchButton.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			tween.to( spatial, 2, { x : 511 });
			_launchButton.add( tween );
			
			// Go light
			var greenLight:Entity = TimelineUtils.convertClip( super.screen.content.leftPanel.greenLight, this );
			id = new Id( "greenLight" );
			timeline = greenLight.get( Timeline );
			timeline.gotoAndStop( 1 );
			greenLight.add( id );
			
			var redLight:Entity = TimelineUtils.convertClip( super.screen.content.leftPanel.redLight, this );
			id = new Id( "redLight" );
			timeline = redLight.get( Timeline );
			timeline.gotoAndStop( 0 );
			redLight.add( id );
			
			
			var sineWave:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.rightContent.sineWave );
			id = new Id( "sineWave" );
			sineWave.add( id );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( sineWave )), this, sineWave );
			
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, startDialog ));
		} 
		
		private function dispatchClang():void
		{
			panelClang.dispatch();
			screenStatic.dispatch();
		}
		
		private function launchWebSite(...args ):void
		{
			buttonClick.dispatch();
			var req:URLRequest = new URLRequest( "https://www.poptropica.com/island-tour/virus-hunter-island.html" );
			navigateToURL(req, '_blank');
		}
		
		private function startDialog():void
		{
			var tween:Tween = _trainingScreen.get( Tween );
			var display:Display = _trainingScreen.get( Display );
			tween.to( display, 2, { alpha : 1 });
			
			var drLang:Entity = super.getEntityById( "drLang" );
		
			Dialog( drLang.get( Dialog )).sayById( "intro" );
			Dialog( drLang.get( Dialog )).complete.addOnce( introDialogComplete );
		}
			
		private function introDialogComplete( dialogData:DialogData ):void
		{
			var tween:Tween = _startButton.get( Tween );
			var display:Display = _startButton.get( Display );
			display.visible = true;
			
			tween.to( display, 2, { alpha : 1, onComplete : addStartTooltip });
		}
		
		private function addStartTooltip():void
		{
			ToolTipCreator.addToEntity( _startButton );
		}
		
		private function addLaunchTooltip():void
		{
			ToolTipCreator.addToEntity( _launchButton );
		}
		
		private function startButtonClicked( ...args ):void
		{
			buttonClick.dispatch();
			var entity:Entity = _startButton.get( Children ).children[ 0 ];
			removeEntity( entity );
			
			var tween:Tween = _trainingScreen.get( Tween );
			var display:Display = _trainingScreen.get( Display );
			var spatial:Spatial = _trainingScreen.get( Spatial );
	
			tween.to( display , 2, { alpha : 0, onComplete : loadSecondScreen });
			
			tween = _startButton.get( Tween );
			display = _startButton.get( Display );
			 
			tween.to( display, 2, { alpha : 0 });
			
			var drLang:Entity = super.getEntityById( "drLang" );
			
			Dialog( drLang.get( Dialog )).sayById( "ready" );
			Dialog( drLang.get( Dialog )).complete.addOnce( readyDialogComplete );
		}
		
		private function loadSecondScreen( ):void
		{
			var timeline:Timeline = _trainingScreen.get( Timeline );
			timeline.gotoAndStop( 1 );
			
			var display:Display = _trainingScreen.get( Display );
			var tween:Tween = _trainingScreen.get( Tween );
			
			tween.to( display, 2, { alpha : 1 });
		}
		
		private function readyDialogComplete( dialogData:DialogData ):void
		{
			var tween:Tween = _launchButton.get( Tween );
			var display:Display = _launchButton.get( Display );
			display.visible = true;
			tween.to( display, 2, { alpha : 1, onComplete : addLaunchTooltip });
		}
		
		private function launchButtonClicked( ...args ):void
		{
			buttonClick.dispatch();
			var rightPanel:Entity;
			var contentBackground:Entity;
			var navHeader:Entity;
			var moreInfo1:Entity;
			var moreInfo2:Entity; 
			
			var display:Display;
			var spatial:Spatial;
			var timeline:Timeline;
			var tween:Tween;
			
			rightPanel = super.getEntityById( "rightPanel" );
			tween = rightPanel.get( Tween );
			spatial = rightPanel.get( Spatial );
			tween.to( spatial, 2, { x : 1219, onComplete : launchDemoGame });
			closePanel.dispatch();
			
			contentBackground = super.getEntityById( "contentBackground" );
			tween = contentBackground.get( Tween );
			spatial = contentBackground.get( Spatial );
			tween.to( spatial, 2, { x : 980 });
			
			navHeader = super.getEntityById( "navHeader" );
			tween = navHeader.get( Tween );
			spatial = navHeader.get( Spatial );
			tween.to( spatial, 2, { x : 982 });
				
		//	moreInfo1 = super.getEntityById( "moreInfo1" );
			tween = _moreInfo1Button.get( Tween );
			spatial = _moreInfo1Button.get( Spatial );
			tween.to( spatial, 2, { x : 1065 });
			
		//	moreInfo2 = super.getEntityById( "moreInfo2" );
			tween = _moreInfo2Button.get( Tween );
			spatial = _moreInfo2Button.get( Spatial );
			tween.to( spatial, 2, { x : 1404 });
					
			tween = _launchButton.get( Tween );
			spatial = _launchButton.get( Spatial );
			display = _launchButton.get( Display );
			
			tween.to( display, 2, { alpha : 0 });
			tween.to( spatial, 2, { x : 1066 });
			
			tween = _trainingScreen.get( Tween );
			spatial = _trainingScreen.get( Spatial );
			display = _trainingScreen.get( Display );
			
			tween.to( display, 2, { alpha : 0 });
			tween.to( spatial, 2, { x : 1040 });
			
			var drLang:Entity = super.getEntityById( "drLang" );
			
			Dialog( drLang.get( Dialog )).sayById( "launch" );
			Dialog( drLang.get( Dialog )).complete.addOnce( sendLaunchSignal );
		}
		
		private function sendLaunchSignal( ...args ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, lightChange ));
		}
		
		private function lightChange():void
		{
			var greenLight:Entity;
			var redLight:Entity;
			var timeline:Timeline; 
			
			switchLights.dispatch();
			greenLight = super.getEntityById( "greenLight" );
			timeline = greenLight.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			redLight = super.getEntityById( "redLight" );
			timeline = redLight.get( Timeline );
			timeline.gotoAndStop( 1 );	
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, pullPanelsAway ));
		}
		
		private function pullPanelsAway():void
		{			
			var leftPanel:Entity;
			var charHolder:Entity;
			var charBackground:Entity;
			var greenLight:Entity;
			var tween:Tween;
			var spatial:Spatial;
			
			leftPanel = super.getEntityById( "leftPanel" );
			tween = leftPanel.get( Tween );
			spatial = leftPanel.get( Spatial );
			tween.to( spatial, 2, { x : -105.8 });
			closePanel.dispatch();
			
			charHolder = super.getEntityById( "charHolder" );
			tween = charHolder.get( Tween );
			spatial = charHolder.get( Spatial );
			tween.to( spatial, 2, { x : -280 });
			
			charBackground = super.getEntityById( "charBackground" );
			tween = charBackground.get( Tween );
			spatial = charBackground.get( Spatial );
			tween.to( spatial, 2, { x : -255 });		
		}
		
		private function launchDemoGame( ):void
		{
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
						tween.to( display, 2, { alpha : 1, onComplete : loadExperiment });
						floatingInterface.add( tween );
					
						timeline.paused = true;
						_backgroundOpen = true;
					}
					break;
				case "stopEnd":
					display = floatingBackground.get( Display );
					display.visible = false; 
					startSignal.dispatch();
			}
		}
		
		private function loadExperiment():void
		{
			var elipsee:Entity;
			var leftPanel:Entity;
			var rightPanel:Entity;
			var display:Display;
			var spatial:Spatial;
			var tween:Tween = new Tween();
			
			if( _number < 4 )
			{
				elipsee = super.getEntityById( "elipsee" + _number );
				display = elipsee.get( Display );
				_number ++;
				tween.to( display, 1, { alpha : 1, onComplete : loadExperiment });
				elipsee.add( tween );
			}
			else
			{
				leftPanel = super.getEntityById( "leftPanel" );
				tween = leftPanel.get( Tween );
				spatial = leftPanel.get( Spatial );
				tween.to( spatial, 1, { x : -200 });
				closePanel.dispatch();
				
				rightPanel = super.getEntityById( "rightPanel" );
				tween = rightPanel.get( Tween );
				spatial = rightPanel.get( Spatial );
				tween.to( spatial, 1, { x : 1300 });
				
				readyExperiment();
			}
		}
		
		private function readyExperiment():void
		{
			var floatingInterface:Entity = super.getEntityById( "floatingInterface" );
			var tween:Tween = floatingInterface.get( Tween );
			var display:Display = floatingInterface.get( Display );
			
			tween.to( display, 1, { alpha : 0, onComplete : startExperiment });
		}
		
		private function startExperiment( ):void
		{
			var floatingBackground:Entity = super.getEntityById( "floatingBackground" );
			var timeline:Timeline = floatingBackground.get( Timeline );
			loadScreen.dispatch();
			timeline.paused = false;
		}
		
		public var startSignal:Signal;
		public var buttonClick:Signal;
		public var openPanel:Signal;
		public var closePanel:Signal
		public var panelClang:Signal;
		public var screenStatic:Signal;
		public var loadScreen:Signal;
		public var switchLights:Signal;
		
		private var _number:int = 1;
		private var _backgroundOpen:Boolean = false;
		private var _startClicked:Signal;
		private var _launchClicked:Signal;
		private var _startButton:Entity;
		private var _launchButton:Entity;
		private var _moreInfoClicked:Signal;
		private var _moreInfo1Button:Entity;
		private var _moreInfo2Button:Entity;
		private var _trainingScreen:Entity;
	}
}