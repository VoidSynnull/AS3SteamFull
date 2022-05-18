package game.scenes.carnival.shared.popups.duckGame
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.data.TimedEvent;
	import game.scenes.carnival.CarnivalEvents;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class DuckGamePopup extends Popup
	{
		private var _events:CarnivalEvents;
		private var content:MovieClip;
		private var duckStartPositions:Vector.<Point> = new Vector.<Point>();
		
		private var _duckMoverSystem:DuckMoverSystem;
		private var _poleHookConnection:PoleHookConnection;
		private var _correctSequence:Array = [1,2,3,4]
		
		private static const CAUGHT_DUCK_X:Number = 110
		private static const CAUGHT_DUCK_Y:Number = 100
		private static const CAUGHT_DUCK_V_SPACING:Number = 100
		
		private var _ducks:Array;
		private var _ducksCaught:Array;
		private var _gameLost:Boolean;
		
		public function DuckGamePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/carnival/shared/popups/";
			super.screenAsset = "duckGamePopup.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			setUp();
			super.loadCloseButton();
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event ==_events.USED_BLACK_LIGHTBULB)
			{
				super.shellApi.getItem( _events.FLASHLIGHT_BLACK, null, true );	
				super.shellApi.removeItem( _events.BLACK_LIGHTBULB );
				switchToBlackLight()
			}
		}
		
		private function setUp():void
		{
			var mc:MovieClip
			var e:Entity;
			var i:int;
			var iMax:int
			var colorNum:int
			var sp:Spatial
			
			_ducks = []
			_ducksCaught = []
			content = screen.content as MovieClip;
			
			// Ducks
			var _duckContainer:MovieClip = content["duckContainer"];
			iMax = _duckContainer.numChildren;
			var mcs:Array = []
			
			for(i = 0; i < iMax; i++)
			{
				mc = MovieClip(_duckContainer.getChildAt(i))
				if (mc) mcs.push(mc )
			}
			
			colorNum =  0 // super.shellApi.checkEvent(_events.SET_EVENING) ? 4 : 0
			
			// All set initially to yellow or purple. If have blacklight, will set to all colors later in code.
			for( i = 0; i < mcs.length; i++){
				mc = mcs[i];
				mc.gotoAndStop(colorNum+1)
				mc.duck.mcTf.mcFormulaPiece.visible = false
				e = EntityUtils.createSpatialEntity(this, mc, _duckContainer);
				e.add(new Id("duck"+i));
				addDuckMoverComponent(e)
				e.add (new Tween ())
				var cn:ColorNum = new ColorNum
				cn.num = colorNum
				e.add (cn)
				_ducks.push (e)
			}
			
			if (hasBlackLight) {
				switchToBlackLight()
			}
			
			_duckMoverSystem  = new DuckMoverSystem
			addSystem(_duckMoverSystem);
			_duckMoverSystem.duckCaught.add(onDuckCaught)
			
			// Pole
			mc = content ["pole"]
			var poleEntity:Entity = EntityUtils.createMovingEntity(this, mc, content);
			poleEntity.get(Spatial).x = 0
			sp = super.shellApi.inputEntity.get(Spatial)
			var follow:FollowTarget = new FollowTarget(shellApi.inputEntity.get(Spatial));
			follow.offset = new Point(0, -150);
			poleEntity.add(follow);
			
			mc = content ["cover"]
			e = EntityUtils.createSpatialEntity(this, mc, content);
			var interaction:Interaction = InteractionCreator.addToEntity(e, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.OUT]);
			interaction.up.add(Command.create(onScreenMouseUp ));
			interaction.down.add(Command.create(onScreenMouseDown));
			
			mc = content ["hook"]
			var hookEntity:Entity = EntityUtils.createMovingEntity(this, mc, content);
			hookEntity.get(Spatial).x = 0
			sp = super.shellApi.inputEntity.get(Spatial)
			follow = new FollowTarget(shellApi.inputEntity.get(Spatial),.05);
			follow.offset = new Point(50, -80);
			hookEntity.add(follow);
			
			// Wire Connector
			mc = content ["wireContainer"]
			e = EntityUtils.createMovingEntity(this, mc, content);
			_poleHookConnection = new PoleHookConnection()
			_poleHookConnection.entity1 = poleEntity
			_poleHookConnection.entity2 = hookEntity
			_poleHookConnection.followOffsetYMin = follow.offset.y
			_poleHookConnection.followOffsetYMax = 100
			_poleHookConnection.followOffsetDy = 0;
			e.add(_poleHookConnection)
			_duckMoverSystem.poleHookConnector = e
			
			var wcs:PoleHookConnectorSystem = new PoleHookConnectorSystem()
			addSystem (wcs)
			
			_gameLost = false
			
			mc = content ["mcSecretMessage"]
			//e = EntityUtils.createMovingEntity(this, mc, content);
			if (super.shellApi.checkHasItem(_events.SECRET_MESSAGE)) {
				
			} else {
				mc.visible = false
			}
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "small_water_lapping_01_loop.mp3",.6,true);
			
		}
		
		private function switchToBlackLight():void {
			var mc:MovieClip
			var e:Entity
			var colorNum:int
			for( var i:int = 0; i < _ducks.length; i++){
				e = _ducks[i]
				mc = MovieClip( Display(e.get(Display)).displayObject)
				colorNum = 1 + i%4
				mc.gotoAndStop(colorNum+1)
				var cn:ColorNum = new ColorNum
				cn.num = colorNum
				e.add (cn)
			}
		}
		
		private function get hasBlackLight():Boolean
		{
			trace ("[DuckGamePopup] super.shellApi.checkItem(_events.FlashlightBlack):" + super.shellApi.checkHasItem(_events.FLASHLIGHT_BLACK))
			//return true
			return super.shellApi.checkHasItem(_events.FLASHLIGHT_BLACK)
		}
		
		private function addDuckMoverComponent(e:Entity):void
		{
			var speed:Number = 1.6 + Math.random() * .6 
			var sp:Spatial
			var c:DuckMover
			sp = e.get(Spatial)
			sp.rotation = Math.random() * 360
			c = new DuckMover()
			var pt:Point = Point.polar(speed,sp.rotation * Math.PI / 180)
			c.dx = pt.x
			c.dy = pt.y;
			e.add (c);
		}
		
		private function onDuckCaught(e:Entity):void
		{
			var str:String 
			_ducksCaught.push (e)
			
			//trace ("super.shellApi.checkItem(_events.BLACK_LIGHTBULB):" + super.shellApi.checkItem(_events.BLACK_LIGHTBULB))
			
			var mc:MovieClip = MovieClip (Display(e.get(Display)).displayObject)
			mc.parent.addChild (mc)
			if (hasBlackLight) {
				// Check if right next one in the sequence
				var colorNum:int = ColorNum(e.get(ColorNum)).num
				//trace ("_correctSequence[_ducksCaught.length-1]:" + _correctSequence[_ducksCaught.length-1] + " = " + colorNum + "???")
				if (colorNum == _correctSequence[_ducksCaught.length-1]) {
					str = ""
					mc.duck.mcTf.mcFormulaPiece.visible = true
					mc.duck.mcTf.mcFormulaPiece.gotoAndStop(colorNum)
				} else {
					str = "Oops, wrong order"
					_gameLost = true
					mc.duck.mcTf.mcFormulaPiece.visible = false
				}
			} else {
				str = "Sorry, not a winner."
				mc.duck.mcTf.mcFormulaPiece.visible = false
				
			}
			
			if (mc["duck"]["mcTf"]){
				mc["duck"]["mcTf"].tf.text = str
			}
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_hit_dirt_01.mp3");
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.5,1,dropCaughtDuck));
			//trace ("[DuckGamePopup]  duck caught:")
		}
		
		private function dropCaughtDuck():void {
			trace ("[DuckGamePopup] dropCaughtDuck")
			if (_poleHookConnection.duckOnLine) {
				var duck:Entity = _poleHookConnection.duckOnLine
				var mc:MovieClip = MovieClip (Display(duck.get(Display)).displayObject)
				mc["duck"].gotoAndPlay ("submerged")
				duck.remove(FollowTarget);
				SceneUtil.addTimedEvent(this, new TimedEvent(.5,1,moveCaughtDuckToSide));
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "small_splash_0" + (Math.floor(Math.random()*5) + 1) + ".mp3");
			}
		}
		
		private function moveCaughtDuckToSide ():void {
			trace ("[DuckGamePopup] moveCaughtDuckToSide")
			raisePole()
			var duck:Entity = _poleHookConnection.duckOnLine
			
			var t:Tween = new Tween()
			t.to (duck.get(Spatial), .7, {x: CAUGHT_DUCK_X, y: CAUGHT_DUCK_Y + _ducksCaught.length * CAUGHT_DUCK_V_SPACING, scaleX:2, scaleY:2, rotation:0, onComplete:afterDuckPlaced,ease:Sine.easeOut})
			duck.add(t);
		}
		
		private function afterDuckPlaced ():void {
			trace ("[DuckGamePopup] afterDuckPlaced")
			var t:Tween
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "put_misc_item_down_01.mp3");
			
			if (hasBlackLight) {
				if (!_gameLost) {
					var ltr:String =  ["a","b","c","d"][_ducksCaught.length-1]
					var str:String =  "points_ping_01"+ ltr + ".mp3"
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + str);
					var d:Entity = _ducksCaught[_ducksCaught.length-1]
					t = new Tween()
					var sp:Spatial = d.get(Spatial)
					t.to (sp,.3,{scaleX:sp.scaleX * 1.2,scaleY:sp.scaleY*1.2, yoyo:true, repeat:1, ease:Sine.easeInOut})
					d.add(t)
				} 
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,checkDuckPlacedResult));
		}
		
		private function checkDuckPlacedResult():void {
			trace ("[DuckGamePopup] checkDuckPlacedResult")
			var i:int
			var t:Tween
			var time:Number = 1
			var clearDucks:Boolean = false
			if (hasBlackLight) {
				if (!_gameLost) {
					if (_ducksCaught.length == 4) {
						winGame()
					}
				} else {
					clearDucks = true
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "alarm_04.mp3");
				}
			} else {
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "whoosh_09.mp3");
				clearDucks = true
			}
			
			if (clearDucks) {
				for each (var e:Entity in _ducksCaught) {
					// to do: add duck back to pond
					t = e.get(Tween);
					t.to (e.get(Spatial), time, {y: 1000, ease:Sine.easeInOut})
				}
				_gameLost = false
				// Only clear ducks if actual game in progress
				if (hasBlackLight) {
					SceneUtil.addTimedEvent(this, new TimedEvent(time+.1,1,putDucksBackInPond));
				} else {
					_ducksCaught = []
				}
				SceneUtil.addTimedEvent(this, new TimedEvent(time+.11,1,allowCatchDucks)); 
			} else {
				allowCatchDucks()
			}
			
		}
		
		private function allowCatchDucks ():void {
			//trace ("-------allowCatchDucks:")
			_poleHookConnection.duckOnLine = null
		}
		
		private function putDucksBackInPond ():void {
			var e:Entity
			var sp:Spatial
			var mc:MovieClip
			var pt:Point
			for  (var i:int = 0; i< _ducksCaught.length ; i++) {
				e = _ducksCaught[i]
				sp = e.get(Spatial)
				pt = findEmptySpotInPond(e)
				sp.x = pt.x
				sp.y = pt.y
				sp.scaleX = 1
				sp.scaleY = 1
				addDuckMoverComponent(e)
				mc = MovieClip (Display(e.get(Display)).displayObject);
				mc["duck"].gotoAndPlay (1)
				//var t:Tween = e.get(Tween);
				//t.to (e.get(Spatial), 1, {delay:i * .3, x:DuckMoverSystem.CENTER_X, y:DuckMoverSystem.CENTER_Y, ease:Sine.easeInOut})
			}
			_ducksCaught = []
		}
		
		
		private function findEmptySpotInPond(e:Entity):Point
		{
			var pt1:Point = new Point()
			var numTriesLeft:int = 500
			var duck:Entity
			var sp1:Spatial = e.get(Spatial)
			var sp2:Spatial
			var pt2:Point;
			var duckTooClose:Boolean
			
			while (numTriesLeft > 0 ){
				numTriesLeft--;
				//trace ("numTriesLeft:" + numTriesLeft)
				//if (numTriesLeft ==0 ) trace ("[DuckGamePopup] ran out of tries!")
				
				pt1.x = DuckMoverSystem.CENTER_X - DuckMoverSystem.POND_RADIUS + 50 + Math.random() * (DuckMoverSystem.POND_RADIUS * 2 - 100)
				pt1.y = DuckMoverSystem.CENTER_Y - DuckMoverSystem.POND_RADIUS + 50 + Math.random() * (DuckMoverSystem.POND_RADIUS * 2 - 100)
				duckTooClose = false;
				for each (duck in _ducks) {
					if (duck != e) {
						sp2 = duck.get(Spatial)
						pt2 = new Point (sp2.x, sp2.y)
						if (Point.distance(pt1,pt2) < DuckMoverSystem.DUCK_RADIUS*2.7)  {
							duckTooClose = true
							//trace ("duck too close!")
						}
					}
				}
				if (!duckTooClose) {
					numTriesLeft = 0
				}
			}
			return pt1
		}
		
		private function onScreenMouseDown(e:Entity = null):void
		{
			//trace ("[DuckGamePopup] screenMouseDown")
			//if (!_poleHookConnection.duckOnLine) 
			_poleHookConnection.followOffsetDy = 10
		}
		
		private function onScreenMouseUp(e:Entity = null):void
		{
			//trace ("[DuckGamePopup] screenMouseUp")
			raisePole()
			//dropCaughtDuck()
		}
		
		private function raisePole():void {
			_poleHookConnection.followOffsetDy = -20
		}
		
		private function winGame():void {
			super.shellApi.getItem(_events.FORMULA,null,true);
			SceneUtil.addTimedEvent(this, new TimedEvent(.7,1,delayedClose))
		}
		
		private function reset(entity:Entity):void
		{
			
		}
		
		private function delayedClose():void
		{
			super.close();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}


