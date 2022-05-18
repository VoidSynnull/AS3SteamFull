package game.scenes.mocktropica.server{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.mocktropica.mainStreet.MainStreet;
	import game.scenes.mocktropica.poptropicaHQ.TrashCanPopup;
	import game.scenes.mocktropica.server.component.SwitchValue;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Server extends PlatformerGameScene
	{
		private var _colors:Array;
		private var _serverLights:Array;
		private var _initialSwitchPositions:Object;
		private var _circuits:Object;
		private var _switches:Object;
		private var _firstPositionRotations:Object;
		private var _circuitsToServerNumber:Object;
		private var _winPositions:Object;
		
		private var _mismatchAnims:Array;
		
		private var _ambientLights:Array;
		
		private var _cameraFollowEntity:Entity;
		private var _events:MocktropicaEvents;
		
		public function Server()
		{
			super();
			_colors = ["blue","green","yellow","red"]
			_initialSwitchPositions = {blue:2,green:2,yellow:0,red:1} 
			_winPositions = {blue:1,green:0,yellow:0,red:2} 
			_firstPositionRotations = {blue:0,green:-90,yellow:0,red:0}
			_circuitsToServerNumber = {}
			_circuitsToServerNumber.blue = [{server:3,match:false},{server:2,match:true},{server:1,match:true}]
			_circuitsToServerNumber.green = [{server:3,match:true},{server:2,match:true},{server:1,match:true}]
			_circuitsToServerNumber.yellow = [{server:1,match:true},{server:3,match:false},{server:0,match:false}]
			_circuitsToServerNumber.red = [{server:0,match:false},{server:1,match:true},{server:0,match:true}]
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/server/";
			
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
			super.loaded();
			_events = MocktropicaEvents(events);
			this.addSystem( new BitmapSequenceSystem(), SystemPriorities.animate );
			
			var mc:MovieClip
			var switchEntity:Entity
			var i:int
			var j:int
			var e:Entity
			
			_circuits = {}
			var tl:Timeline
			_switches = {}
			
			// Switches and circuits
			for each (var c:String in _colors) {
				mc = super._hitContainer["switch_" + c]
				switchEntity = ButtonCreator.createButtonEntity(mc, this);
				mc.entity = switchEntity
				var interaction:Interaction = Interaction(switchEntity.get(Interaction));
				interaction.upNative.add( onSwitchUp );
				switchEntity.add (new SwitchValue (_initialSwitchPositions[c]))
				_switches[c] = switchEntity
				_circuits[c] = []
				for (i = 0; i < 3; i++) {
					mc = super._hitContainer["circuit_" + c + "_" + i]
					//e = BitmapTimelineCreator.convertToBitmapTimeline(mc,true,true );
					e = new Entity()
					e.add(new Display (mc))
					e.add(new Spatial(mc.x,mc.y))
					e.add (new Motion)			
					addEntity(e)
					_circuits[c].push (e)
					tl = e.get(Timeline) as Timeline;
					//mc.gotoAndPlay(2)
					if (tl) tl.stop()
				}
			}
			
			//Server lights
			_serverLights = []
			var obj:Object
			for (i = 0; i < 4; i++) {
				obj = {}
				_serverLights.push (obj)
				for each (c in _colors) {
					mc = super._hitContainer["server_" +i + "_" + c]
					//trace ("i:" + i + " color:" + c + "mc:" + mc)
					//e = BitmapTimelineCreator.convertToBitmapTimeline(mc,true,true );
					e = TimelineUtils.convertClip (mc)
					e.add(new Spatial(mc.x,mc.y))
					e.add (new Motion)			
					addEntity(e)
					obj[c] = e
					tl = e.get(Timeline) as Timeline;
					tl.gotoAndPlay(1)
				}
			}
			
			// Mismatch anims. NOTE: the clip names match the color of the WIRES mis-connecting to them NOT the server light!
			_mismatchAnims = []
			for (i = 0; i < 4; i++) {
				_mismatchAnims.push ({})
				for each (c in _colors) {
					mc = super._hitContainer["mismatch_" + i + "_" + c]
					if (mc) {
						e = TimelineUtils.convertClip (mc)
						e.add(new Spatial(mc.x,mc.y))
						e.add (new Motion)			
						addEntity(e)
						_mismatchAnims[i][c] = e
					}
				}
			}
			
			// Ambient light anims
			i=1
			var n:int = 0
			
			_ambientLights = []
			while (super._hitContainer["light" + i]) {
				mc = super._hitContainer["light" + i]
				var al:AmbientLight = new AmbientLight(mc)
				_ambientLights.push (al)
				i++
			}
			
			mc = super._hitContainer["btnInstructions"]
			e = ButtonCreator.createButtonEntity(mc, this);
			interaction = Interaction(e.get(Interaction));
			interaction.upNative.add(onInstructionsClick) 
			
			DisplayUtils.moveToTop(player.get(Display).displayObject)
			
			// Needs a tick to "get itself together". For some reason, the mismatchAnims get stuck on frame 1, and cannot be cleared by hiding their TimeLineClip.
			SceneUtil.addTimedEvent( this, new TimedEvent( .02, 1 , firstDraw ));
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1 , speakWhereAmI ));
		}
		
		private function firstDraw ():void {
			draw (true)
		}
		
		private function speakWhereAmI():void {
			super.player.get(Dialog).sayById("intro");
		}
		
		private function successCameraMoveComplete ():void {
			trace ("[Server] successCameraMoveComplete")
		}
		
		private function onInstructionsClick (e:Event):void {
			var popup:ServerGameInstructionsPopup = super.addChildGroup( new ServerGameInstructionsPopup( super.overlayContainer )) as ServerGameInstructionsPopup
		}
		
		private function draw(firstTime:Boolean = false):void
		{
			var c:String
			var i:int
			
			var switchEntity:Entity
			var e:Entity
			var b:Boolean
			var mc:*
			var switchPos:int
			var light:Entity
			
			// Turn off all the server lights
			for (i = 0; i < 4; i++) {
				for each (c in _colors) {
					setServerLight(i,c,false)
				}
			}
			
			// Turn off all mismatch anims
			for (i = 0; i < 4; i++) {
				for each (c in _colors) {
					e = _mismatchAnims[i][c]
					if (e) {
						setAnimEntityVisible(e,false)
					}
				}
			}
			
			for each (c in _colors) {
				switchEntity = _switches[c]
				switchPos = switchEntity.get(SwitchValue).value
				mc = Display(switchEntity.get(Display)).displayObject; 
				mc.rotation = _firstPositionRotations[c] + (2-switchPos) * 90
				for (i = 0; i < 3; i++) {
					e = _circuits[c][i]
					b = (i == switchPos)
					setEntityVisible(e, b)
					mc = Display(e.get(Display)).displayObject; 
					if (b) {
						if (mc.currentFrame == 1 || firstTime) {
							mc.gotoAndPlay(2)
						}
						var o:Object = _circuitsToServerNumber[c][i]
						if (o.match) {
							setServerLight(o.server,c,true)
						} else {
							setAnimEntityVisible(_mismatchAnims[o.server][c],true)
						}
					}
					else {
						if (mc.currentFrame != 1) {
							mc.gotoAndPlay ("turn off")
						}
					}
				}
			}
		}
		
		private function setServerLight(i:int, c:String, b:Boolean):void
		{
			var e:Entity = _serverLights[i][c]
			TimelineClip(e.get(TimelineClip)).mc.visible = b
		}
		
		private function setEntityVisible(e:Entity, b:Boolean):void {
			var mc:* = Display(e.get(Display)).displayObject 
			mc.visible = b
		}
		
		private function setAnimEntityVisible(e:Entity, b:Boolean):void {
			TimelineClip(e.get(TimelineClip)).mc.visible = b
		}
		
		private function onDebugClick(e:Event):void
		{
			var popup:TrashCanPopup = super.addChildGroup( new TrashCanPopup( super.overlayContainer )) as TrashCanPopup;
		}
		
		private function onSwitchUp(e:Event):void
		{
			var mc:MovieClip = MovieClip (e.currentTarget)
			var c:String = mc.name.split("_")[1]
			var switchEntity:Entity = mc.entity
			var val:SwitchValue = switchEntity.get(SwitchValue)
			val.value--;
			if (val.value == -1) val.value = 2
			draw()
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1 , checkSolved ));
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_02.mp3");
			SceneUtil.addTimedEvent( this, new TimedEvent( .25, 1 , playZapSound ));
		}
		
		private function playZapSound ():void {
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "electric_zap_05.mp3");
		}
		
		private function checkSolved():void {
			var c:String
			var switchEntity:Entity
			var won:Boolean = true
			var v:int
			for each (c in _colors) {
				switchEntity = _switches[c];
				v = SwitchValue(switchEntity.get(SwitchValue)).value
				if (_winPositions[c] != v) {
					won = false
					//trace ("[Server] sorry, but color " + c + " is incorrect. switch is at:" + v + " but should be:" + _winPositions[c])
				}
			}
			if (won) {
				trace ("[Server] WIIIIIIIIINNNN!!!!")
				win()
			}
		}
		
		private function win():void {
			SceneUtil.lockInput(this, true);
			
			var playerSp:Spatial = player.get(Spatial) as Spatial
			AudioUtils.play(this, SoundManager.MUSIC_PATH + "MiniGameWin.mp3");
			_cameraFollowEntity = new Entity()
			//mc = super._hitContainer["ttt"]
			//cameraFollowEntity.add(new Display (mc))
			_cameraFollowEntity.add(new Motion)
			var spatial:Spatial = new Spatial (playerSp.x, playerSp.y)
			_cameraFollowEntity.add(spatial)
			addEntity(_cameraFollowEntity)
			var tween:Tween = new Tween();
			tween.to(spatial, 2, {x:330, y:1800, onComplete:successAnimServer1Reached},"successAnim0");
			_cameraFollowEntity.add(tween);
			SceneUtil.setCameraTarget( this, _cameraFollowEntity );
		}
		
		private function successAnimServer1Reached ():void {
			var tween:Tween = new Tween();
			var spatial:Spatial = _cameraFollowEntity.get(Spatial)
			tween.to(spatial, 2, {x:2454, y:1800, onComplete:successAnimServer4Reached},"successAnim0");
			_cameraFollowEntity.add(tween);
		}
		
		private function successAnimServer4Reached ():void {
			var tween:Tween = new Tween();
			var playerSp:Spatial = player.get(Spatial) as Spatial
			var spatial:Spatial = _cameraFollowEntity.get(Spatial)
			tween.to(spatial, 2, {x:playerSp.x, y:playerSp.y, onComplete:successAnimBackToPlayer},"successAnim1");
			_cameraFollowEntity.add(tween);
		}
		
		private function successAnimBackToPlayer():void {
			shellApi.completeEvent(_events.SERVER_REPAIRED);
			var playerDialog:Dialog = super.player.get(Dialog);
			playerDialog.sayById("success");

			//set to clear day for finale
			shellApi.triggerEvent(_events.SET_DAY,true);
			shellApi.removeEvent(_events.SET_NIGHT);
			shellApi.triggerEvent(_events.SET_CLEAR,true);
			shellApi.removeEvent(_events.SET_RAIN);

			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1 , returnToMainStreet ));
		}
		
		private function returnToMainStreet():void
		{	
			super.shellApi.loadScene( MainStreet, 3000, 900 );
		}
		
	}
}