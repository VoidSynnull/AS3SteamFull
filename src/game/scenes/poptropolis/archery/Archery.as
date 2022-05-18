package game.scenes.poptropolis.archery{
	
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.input.Input;
	import game.components.motion.WaveMotion;
	import game.components.ui.Cursor;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.data.WaveMotionData;
	import game.data.ui.ToolTipType;
	import game.scene.template.GameScene;
	import game.scenes.poptropolis.archery.components.Arrow;
	import game.scenes.poptropolis.archery.components.Flag;
	import game.scenes.poptropolis.archery.components.Tree;
	import game.scenes.poptropolis.archery.components.Wind;
	import game.scenes.poptropolis.archery.systems.ArcherySystem;
	import game.scenes.poptropolis.common.PoptropolisInstructions;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	public class Archery extends GameScene
	{
		public var _interaction:Interaction;
		private var _interactive:MovieClip;
		private var _powerMeter:Entity;
		private var _powerBar:Entity;
		private var _windGuage:Entity;
		private var _arrowsHud:Entity;
		private var _tree:Entity;
		private var _arrow:Entity;
		private var _inArrow:Entity;
		private var _flag:Entity;
		private var _scoreboard:Entity;
		private var _exitBtn:Entity;
		private var _treeMC:MovieClip;

		private var buttonToolTip:ToolTip;
		
		private var minValidShot:Number = 75;
		private var arrowsLeft:Number = 10;
		private var score:Number = 0;
		private var totalScore:Number = 0;
		private var gameStarted:Boolean = false;
		private var arrowReady:Boolean = false;
		private var hitSound:String = "";
		
		protected var _instructionsPopup:PoptropolisInstructions;
		protected var _practice:Boolean;
		
		public function Archery()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/archery/";
			super.init(container);

		}

		
		// all assets ready
		override public function loaded():void
		{
			_interactive = super.hitContainer as MovieClip;	
			_interactive.mouseEnabled = false;
			
			// add systems
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);           // provides additional motion on top of an entity's standard motion for movement based on math operations like sine waves.
			super.addSystem(new ArcherySystem());

			setupPowerBar();
			setupWindGuage();
			setupTree();
			setupFlag();
			setupArrowsHud();
			setupScoreboard();
			setupExitBtn();
			
			//  set cursor to target is on non-touch device
			if( PlatformUtils.isDesktop ) 
			{
				Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;
			}

			playSound("mainThemeFull");
			
			this.ready.addOnce(delayInstructions);
			//SceneUtil.delay( this, 1, openInstructionsPopup );
			super.loaded();
		}
		
		private function delayInstructions(...args):void
		{
			SceneUtil.delay( this, 1, openInstructionsPopup );
		}
		
		protected function openInstructionsPopup():void
		{
			_instructionsPopup = super.addChildGroup(new PoptropolisInstructions(super.overlayContainer)) as PoptropolisInstructions;
			_instructionsPopup.startClicked.addOnce(onStartClicked)
			_instructionsPopup.practiceClicked.addOnce(onPracticeClicked)
		}
		
		protected function onStartClicked(): void {
			setPracticeMode(false);
			initGame();
		}
		
		protected function onPracticeClicked(): void {
			setPracticeMode(true);
			_exitBtn.add(buttonToolTip);
			
			_exitBtn.get(Display).visible = true;
			initGame();
		}
		
		private function setPracticeMode (b:Boolean):void {
			_practice = b
		}
		
		private function initGame():void 
		{
			gameStarted = true;
			makeArrow();
			tweenFadeIn(_windGuage);
			tweenFadeIn(_powerMeter);
			tweenFadeIn(_arrowsHud);

			(super.shellApi.inputEntity.get( Input ) as Input).inputDown.add( onHandleDown );
			//tweenFadeIn(scoreboard);
		}
		
		private function onHandleDown(input:Input):void {
			if(arrowReady){
				shoot();
			}
		}
		
		private function shoot():void 
		{
			playSound("shoot");
			if(arrowsLeft > 0){
				arrowReady = false;
				var windVariance:Number = -_powerBar.get(SpatialAddition).x;
				if(windVariance > 0){
					windVariance -= 15;
					if(windVariance < 0){
						windVariance = 0;
					}
				}else{
					windVariance += 15;
					if(windVariance > 0){
						windVariance = 0;
					}
				}
				
				Arrow(_arrow.get(Arrow)).targetX = Arrow(_arrow.get(Arrow)).mouse.x + Wind(_windGuage.get(Wind)).windSpeed;
				Arrow(_arrow.get(Arrow)).targetY = Arrow(_arrow.get(Arrow)).mouse.y+10 + windVariance;
				if(Arrow(_arrow.get(Arrow)).targetY < 80){
					Arrow(_arrow.get(Arrow)).targetY = 80;
				}
				
				var dist:Number = resolveScore();
				if(dist < minValidShot){
					Arrow(_arrow.get(Arrow)).finalScale = .25;
					hitSound = "hitTarget";
				}else if(Arrow(_arrow.get(Arrow)).targetY - 5 < 379){
					Arrow(_arrow.get(Arrow)).finalScale = 0;
					hitSound = "arrowMiss";
				}else{
					var ratio:Number = (Arrow(_arrow.get(Arrow)).targetY - 379) / 200;
					var scaleFactor:Number = (ratio * 20 + 10)*.01;
					Arrow(_arrow.get(Arrow)).finalScale = scaleFactor;
					hitSound = "hitDirt";
				}
				
				arrowsLeft--;
				_interactive.arrowsHud.remaining.text = "x "+arrowsLeft;
				_arrow.get(Display).displayObject.arrow.x = -178;
				Arrow(_arrow.get(Arrow)).firing = true;
			}
		}
		
		private function resolveScore():Number
		{
			var dx:Number = Arrow(_arrow.get(Arrow)).targetX - 492; 
			var dy:Number = Arrow(_arrow.get(Arrow)).targetY - 358 - 10; 
			var dist:Number = Math.sqrt(dx*dx + dy*dy);
			
			var s:Number = Math.ceil(10-(((dist)/minValidShot)*10));
			if(s > 0){
				score = s;
				if(!_practice){
					totalScore += s;
				}
			}else{
				score = 0;
			}
			return dist;
		}
		
		private function makeArrow():void {
			super.loadFile("arrow.swf", arrowLoaded);
		}
		
		private function arrowLoaded(clip:MovieClip):void 
		{
			//Get MovieClip from SWF
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			clip.rotation = -135;
			
			//Create and configure entity
			_arrow = new Entity();
			_arrow.add(new Arrow(Input(super.shellApi.inputEntity.get(Input)).target));
			
			var spatial:Spatial = new Spatial();
			spatial.x = 980;
			spatial.y = 628;
			
			_arrow.add(spatial);
			_arrow.add(new Display(clip, super.hitContainer));
			
			//Add entity to group
			_arrow.add(new Id("arrow"+arrowsLeft));
			this.addEntity(_arrow);
			
			Arrow(_arrow.get(Arrow)).arrowReady.addOnce(onReady);
			this._arrow.get(Display).displayObject.arrow.gotoAndStop(1);
			arrowReady = true;
		}
		
		private function onReady():void {
			playHitSound();
			if(arrowsLeft > 0){
				makeArrow();
			}else{
				///////GAME OVER :: Send to scoreboard or instructions screen
				if(_practice)
				{
					super.shellApi.loadScene(Archery);
				}
				else
				{
					//trace("totalScore = "+totalScore);
					var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
					pop.setup();
				}
				tweenFadeOut(_windGuage);
				tweenFadeOut(_powerMeter);
				tweenFadeOut(_arrowsHud);
			}
			showScore();
		}
		
		private function dataLoaded( pop:Poptropolis ):void {
			pop.reportScore( Matches.ARCHERY, totalScore );
		}
		
		private function showScore():void
		{
			if(score != 0){
				//scoreboard.get(Display).alpha = 0;
				_scoreboard.get(Display).displayObject.points.text = score;
				tweenScoreIn(_scoreboard);
				if(score > 0 && score <= 3){
					playSound("1-3");
				}else if(score > 3 && score <= 6){
					playSound("4-6");
				}else if(score > 6 && score <= 9){
					playSound("7-9");
				}else if(score == 10){
					playSound("perfect10");
				}
			}
		}
		
		private function tweenScoreIn(entity:Entity):void{
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), .25, { alpha:1, ease:Sine.easeInOut,	onComplete:tweenScoreOut, onCompleteParams:[entity] });
		}
		
		private function tweenScoreOut(entity:Entity):void{
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), 1, { alpha:0, delay:3, ease:Sine.easeInOut });
		}
		
		private function tweenFadeIn(entity:Entity):void {
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), 0.5, { alpha:1, ease:Sine.easeInOut });
		}
		
		private function tweenFadeOut(entity:Entity):void {
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), 0.5, { alpha:0, ease:Sine.easeInOut });
		}
		
		private function setupExitBtn():void
		{
			var clip:MovieClip = _interactive["exitBtn"];
			_exitBtn = ButtonCreator.createButtonEntity(clip, this);
			var interaction:Interaction = Interaction(_exitBtn.get(Interaction));
			interaction.upNative.add( onExitBtnUp );
			
			buttonToolTip = _exitBtn.get(ToolTip);
			_exitBtn.remove(ToolTip);
			
			_exitBtn.get(Display).visible = false;
		}
		
		private function onExitBtnUp(event:Event):void
		{
			super.shellApi.loadScene(Archery);
		}
		
		private function setupPowerBar():void
		{
			//add powerMeter
			var clip:MovieClip = _interactive["powerMeter"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_powerMeter = new Entity();
			var ps:Spatial = new Spatial();
			ps.x = clip.x;
			ps.y = clip.y;
			_powerMeter.add(ps);
			_powerMeter.add(new Display(clip));
			_powerMeter.add(new Tween());
			super.addEntity(_powerMeter);
			_powerMeter.get(Display).alpha = 0;
			
			//add powerMeter bar
			var vClip:MovieClip = _interactive["powerMeter"]['bar'];
			_powerBar = new Entity();
			
			var vSpatial:Spatial = new Spatial();
			vSpatial.x = vClip.x;
			vSpatial.y = vClip.y;
			
			_powerBar.add(vSpatial);
			_powerBar.add(new Display(vClip));
			
			
			// add wave motion component
			var vWaveMotion:WaveMotion = new WaveMotion();
			var vWaveMotionData:WaveMotionData = new WaveMotionData();
			vWaveMotionData.property = "x";
			vWaveMotionData.magnitude = 120;
			vWaveMotionData.rate = .05;
			vWaveMotionData.radians = 0;
			vWaveMotionData.type = "sin"; // default is "sin"
			vWaveMotion.data.push(vWaveMotionData);
			_powerBar.add(vWaveMotion);
			
			// spatial addition causes the wave motion to be added on top of the spacial x,y values
			var vSpatialAddition:SpatialAddition = new SpatialAddition(); 
			_powerBar.add(vSpatialAddition);
			
			// add entity to system
			super.addEntity(_powerBar);	
			//powerBar.get(Display).alpha = 0;
			//hits.powerMeter.alpha = 0;
		}
		
		private function setupFlag():void 
		{
			var clip:MovieClip = _interactive["flagRight"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_flag = new Entity();
			var vSpatial:Spatial = new Spatial();
			vSpatial.x = 592;
			vSpatial.y = 185;
			
			// add basic properites: spatial and display
			_flag.add(vSpatial);
			_flag.add(new Display(clip));
			var p0:Point = new Point(clip.pt0.x, clip.pt0.y);
			var p1:Point = new Point(clip.pt1.x, clip.pt1.y);
			var p2:Point = new Point(clip.pt2.x, clip.pt2.y);
			var p3:Point = new Point(clip.pt3.x, clip.pt3.y);
			var p4:Point = new Point(clip.pt4.x, clip.pt4.y);
			var p5:Point = new Point(clip.pt5.x, clip.pt5.y);
			_flag.add(new Flag(p0, p1, p2, p3, p4, p5));
			
			// add entity to system
			super.addEntity(_flag);
		}

		private function setupScoreboard():void
		{
			var clip:MovieClip = _interactive["scoreboard"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_scoreboard = new Entity();
			var ss:Spatial = new Spatial();
			ss.x = clip.x;
			ss.y = clip.y;
			_scoreboard.add(ss);
			_scoreboard.add(new Display(clip));
			_scoreboard.add(new Tween());
			super.addEntity(_scoreboard);
			_scoreboard.get(Display).alpha = 0;
		}
		
		private function setupArrowsHud():void
		{
			var clip:MovieClip = _interactive["arrowsHud"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_arrowsHud = new Entity();
			var ahs:Spatial = new Spatial();
			ahs.x = clip.x;
			ahs.y = clip.y;
			_arrowsHud.add(ahs);
			_arrowsHud.add(new Display(clip));
			_arrowsHud.add(new Tween());
			super.addEntity(_arrowsHud);
			_arrowsHud.get(Display).alpha = 0;
		}
		
		private function setupTree():void
		{
			var clip:MovieClip = super.hitContainer.getChildByName("tree") as MovieClip;	
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_tree = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			//spatial.scaleX = spatial.scaleY = 1.5;
			
			_tree.add(spatial);
			_tree.add(new Display(clip));
			_tree.add(new Tree());
			
			super.addEntity(_tree);	
			
			//tree.get(Display).alpha = .5;
		}
		
		private function setupWindGuage():void
		{
			var clip:MovieClip = _interactive["windGuage"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_windGuage = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			_windGuage.add(spatial);
			_windGuage.add(new Display(clip));
			_windGuage.add(new Tween());
			
			_windGuage.add(new Wind());
			
			super.addEntity(_windGuage);	
			_windGuage.get(Display).displayObject.windSpeed.text = Math.abs(Math.ceil(Wind(_windGuage.get(Wind)).windSpeed/5));
			_windGuage.get(Display).alpha = 0;
		}
		
		private function playHitSound():void
		{
			playSound(hitSound);	
		}
		
		private function playSound(sound:String):void {
			switch(sound){
				case "mainThemeFull":
					AudioUtils.play(this, SoundManager.MUSIC_PATH + "Poptropolis_Main_Theme_Full.mp3", 1, true);
					break;
				case "shoot":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "snap_band_01.mp3");
					break;
				case "hitDirt":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_hit_dirt_01.mp3");
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					break;
				case "hitTarget":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_hit_target_board_01.mp3");
					break;
				case "arrowMiss":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_miss_01.mp3");
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					break;
				case "perfect10":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03d.mp3");
					break;
				case "7-9":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03c.mp3");
					break;
				case "4-6":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03b.mp3");
					break;
				case "1-3":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03a.mp3");
					break;
				case "missPoint":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					break;
			}
		}
		
		override public function destroy():void
		{
			//disposeSceneryBitmaps();
			super.destroy();
		}
		/*
		private function disposeSceneryBitmaps():void {
			for(var n:int = 0; n < _bitmapWrappers.length; n++)
			{
				BitmapWrapper(_bitmapWrappers[n]).destroy();
			}
		}
		*/
	}
}


