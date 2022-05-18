package game.scenes.carnival.autoRepair{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.Ceiling;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Salute;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.item.SceneItemData;
	import game.data.scene.hit.HitType;
	import game.data.scene.labels.LabelData;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.autoRepair.components.HydraulicDirection;
	import game.scenes.carnival.autoRepair.systems.HydraulicMoverSystem;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	public class AutoRepair extends PlatformerGameScene
	{
		private var _hydraulics:Vector.<Entity>;
		private var _hydraulicMoverSystem:HydraulicMoverSystem;
		private var _grinder:Entity
		private var _lamp:Entity;
		private var _ventCover:Entity;
		private var _events:CarnivalEvents;
		private var _ventBlocker:Entity;
		private var _ventDoor:Entity;
		private var _car:Entity;
		private var _marnie:Entity;
		private var _hoseCover:Entity;
		private var _hose:Entity;
		
		public function AutoRepair()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/autoRepair/";
			
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
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			var i:int
			var e:Entity
			
			//	this.shellApi.completeEvent(_events.SET_NIGHT)
			//	this.shellApi.removeEvent(_events.SET_DAY)
			
			_events = CarnivalEvents(events);
			setupHydraulicsAndCar();
			var hitCreator:HitCreator = new HitCreator();
			_ventBlocker = hitCreator.createHit(super._hitContainer["ventBlocker"], HitType.CEILING, null, this);
			_grinder = EntityUtils.createSpatialEntity(this, this._hitContainer["grinder"]);
			_grinder.add(new Audio)
			setGrinder (false)
			
			var btnGrinder:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnGrinder"]), this);
			btnGrinder.remove(Timeline);
			btnGrinder.get(Interaction).up.add( Command.create( onGrinderClick ));
			Display(btnGrinder.get(Display)).isStatic = false;
			
			_lamp = EntityUtils.createSpatialEntity(this, this._hitContainer["lamp"]);
			setLamp (false)
			
			var btn:Entity;
			btn = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnLamp"]), this);
			btn.remove(Timeline);
			btn.get(Interaction).up.add( Command.create( toggleLamp ));
			Display(btn.get(Display)).isStatic = false;
			
			_ventDoor = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["ventDoor"]), this);
			_ventDoor.remove(Timeline);
			_ventDoor.get(Interaction).up.add( Command.create( onClickVent ));
			Display(_ventDoor.get(Display)).isStatic = false;
			
			_ventCover = EntityUtils.createSpatialEntity(this, this._hitContainer["ventCover"]);
			
			// Oil cans
			for ( i = 0; i < 4; i++) {
				e = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnOil"+i]), this);
				e.remove(Timeline);
				e.get(Interaction).down.add( Command.create( onClickOil ));
				Display(e.get(Display)).isStatic = false;
			}
			
			// Auto parts
			for ( i = 0; i < 2; i++) {
				e = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnAutoParts"+i]), this);
				e.remove(Timeline);
				e.get(Interaction).up.add( Command.create( onClickAutoParts ));
				Display(e.get(Display)).isStatic = false;
			}
			
			if(this.shellApi.checkEvent(_events.SET_NIGHT) || this.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				removeEntity(_car)
			} 
			
			_marnie = super.getEntityById("marnie");
			
			// remove marnie if island is completed 
			
			if(this.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				super.removeEntity(_marnie);
			}
			
			var needToBlockHose:Boolean = false
			if (this.shellApi.checkEvent(_events.TALKED_TO_DUCK_GAME_WORKER)) {
				if (!super.shellApi.checkEvent(_events.SPOKE_MARNIE_HOSE)) needToBlockHose = true
				if (!super.shellApi.checkHasItem(_events.HOSE)) {
					if (!super.shellApi.checkHasItem(_events.SPOKE_MARNIE_HOSE)) {
						if (!this.shellApi.checkEvent(_events.WATER_FIXED)){
							setUpGetHoseActionChain() 
						} else {
							
						}
					} else {
						needToBlockHose = false
					}
				}
			} else {
				needToBlockHose = true
			}
			
			_hoseCover = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnHoseCover"]), this);
			_hoseCover.remove(Timeline); 
			_hoseCover.get(Interaction).up.add( Command.create( onClickHoseCover ));
			Display(_hoseCover.get(Display)).isStatic = false;
			_hitContainer.setChildIndex(Display(_hoseCover.get(Display)).displayObject, _hitContainer.numChildren-1);
			
			if (!shellApi.checkEvent(_events.STARTED_BONUS_QUEST)) {
				removeEntity(getEntityById("pickle_juice"));
			}
			
			if (!needToBlockHose) { 
				hideDummyHose()
			}	
			
		}
		
		private function hideDummyHose():void {
			if (_hoseCover) {
				removeEntity(_hoseCover)
			}
		}
		
		private function addHoseEntity():void {
			if (!super.shellApi.checkHasItem(_events.HOSE)) {
				var newItem:SceneItemData = new SceneItemData();
				newItem.id = "hose"
				newItem.asset = "hose.swf";
				newItem.x = 850;
				newItem.y = 622;
				newItem.label = new LabelData();
				newItem.label.text = "Examine";
				newItem.label.type = "exitDown";
				var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
				itemGroup.addSceneItemByData(newItem);
			}
		}
		
		private function setUpGetHoseActionChain():void 
		{			
			//	trace ("[AutoRepair]  setupGetHoseActionChain")
			
			CharUtils.setDirection( player, true );
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new MoveAction( _marnie, new Point( 585, player.get(Spatial).y ) ) );
			actChain.addAction( new TalkAction( _marnie, "carTrouble" ) );
			actChain.addAction( new TalkAction( player, "carTroubleAnswer" ) );
			actChain.addAction( new CallFunctionAction( Command.create(setMarnieConversationToHose, true) ) );
			// yes have to set it twice. This one triggers it, where the line above sets it as the default in case kid clicks off and on again.
			actChain.addAction( new TalkAction( _marnie, "hoseConversation" ))
			actChain.execute(this.getHoseActionChainComplete);			
			lockControl();
		} 
		
		private function setMarnieConversationToHose( ...args):void {
			Dialog(_marnie.get(Dialog)).setCurrentById("hoseConversation");	
		}
		
		private function getHoseActionChainComplete( ...args ):void 
		{	
			//restoreControl();			
		} 
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			// trace ("event*:" + event)
			switch (event){
				case _events.USED_BLUNT_DART:
					var actChain:ActionChain = new ActionChain( this );
					actChain.lockInput = true;			
					actChain.addAction( new MoveAction( super.player, new Point( 200,978 ) ) );
					actChain.addAction( new CallFunctionAction( Command.create(setGrinder, true ) ) );
					actChain.execute(this.useBluntDartActionComplete);			
					lockControl();
					break
				case "ask_hose_wrong":
					Dialog(_marnie.get(Dialog)).setCurrentById("hoseConversation");	
					break
				case "ask_hose_right":
					super.shellApi.triggerEvent(_events.SPOKE_MARNIE_HOSE, true );
					Dialog(_marnie.get(Dialog)).setCurrentById("info");	
					break
				case "continue_scene":
					restoreControl();			
					break
				case _events.SPOKE_MARNIE_HOSE:
					addHoseEntity()
					SceneUtil.addTimedEvent(this, new TimedEvent(.5,0,hideDummyHose))		
					break
			}
		}
		
		private function useBluntDartActionComplete( ...args):void {
			CharUtils.setAnim(player, Salute);
			SceneUtil.addTimedEvent(this, new TimedEvent(.7,1,grantSharpenedDart))	
		}
		
		private function grantSharpenedDart ():void {
			super.shellApi.getItem( _events.SHARPENED_DART, null, true );	
			super.shellApi.removeItem( _events.BLUNTED_DART );	
			setGrinder(false)
			restoreControl()
		}
		
		private function onClickHoseCover(e:Entity):void
		{
			if (this.shellApi.checkEvent(_events.TALKED_TO_DUCK_GAME_WORKER)) {
				if (!super.shellApi.checkEvent(_events.SPOKE_MARNIE_HOSE)) {
				super.player.get(Dialog).sayById("hosePermission");
					
				}
			}
			else {
				super.player.get(Dialog).sayById("clickCarParts");
			}
		}
		
		private function onClickVent(e:Entity):void
		{
			trace ("[AutoRepair] this.shellApi.checkEvent(_events.SET_NIGHT:" + this.shellApi.checkEvent(_events.SET_NIGHT))
			
			if (this.shellApi.checkEvent(_events.SET_NIGHT)){
				setVentOpen(true)
			} else {
				super.player.get(Dialog).sayById("clickVentClosed");
			}
		}
		
		private function onClickOil(e:Entity):void
		{
			trace ("[AutoRepair] onClickOil. uper.shellApi.checkEvent(_events.SPOKE_WITH_FERRIS_WORKER:" + super.shellApi.checkEvent(_events.SPOKE_WITH_FERRIS_WORKER))
			trace (e)
			if(!super.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				if(super.shellApi.checkEvent(_events.SPOKE_WITH_FERRIS_WORKER) && super.shellApi.checkEvent(_events.SET_EVENING) && !super.shellApi.checkHasItem(_events.FRY_OIL)){
					var actChain:ActionChain = new ActionChain( this );
					actChain.addAction( new MoveAction(_marnie, new Point( player.get(Spatial).x + 150,978 ) ) );
					actChain.addAction( new TalkAction (_marnie,"tryFryOil"));
					actChain.execute();			
				} else {
					player.get(Dialog).sayById("clickMotorOil");
				}
			}
		}
		
		private function onClickAutoParts(e:Entity):void
		{
			super.player.get(Dialog).sayById("clickCarParts");
		}
		
		private function toggleLamp (e:Entity):void {
			var mc:MovieClip = MovieClip(Display(_lamp.get(Display)).displayObject)
			setLamp (mc.currentFrame == 1) 
		}
		
		private function setLamp(b:Boolean):void
		{
			var mc:MovieClip = MovieClip(Display(_lamp.get(Display)).displayObject)
			if (b) {
				mc.gotoAndStop(2)
			} else {
				mc.gotoAndStop(1)
			}
		}
		
		private function setVentOpen(b:Boolean=true):void {
			var d:Display = Display(_ventCover.get(Display))
			d.alpha = b ? .5 : 1
			Sleep(_ventBlocker.get(Sleep)).sleeping = true
			_ventBlocker.remove(Ceiling)
			var t:Tween = new Tween()
			var sp:Spatial = _ventDoor.get(Spatial)
			t.to(sp,.6,{x: sp.x + 300, y:sp.y + 300,  rotation:sp.rotation + 180, ease:Sine.easeInOut})
			_ventDoor.add (t)
			_ventCover.get(Display).displayObject.parent.addChild(_ventCover.get(Display).displayObject);
		}
		
		private function isVentOpen():Boolean {
			return _ventBlocker.get(Ceiling) == null
		}
		
		private function onGrinderClick (e:Entity):void {
			if (!isGrinderAnimating()){
				super.player.get(Dialog).sayById("clickBevelMachine");
			}
			toggleGrinder()
		}
		
		private function isGrinderAnimating():Boolean {
			var mc:MovieClip = MovieClip(Display(_grinder.get(Display)).displayObject)
			return mc.isPlaying
		}
		
		private function toggleGrinder (e:Entity=null):void {
			setGrinder (!isGrinderAnimating()) 
		}
		
		private function setGrinder(b:Boolean):void
		{
			var mc:MovieClip = MovieClip(Display(_grinder.get(Display)).displayObject)
			var a:Audio = _grinder.get(Audio)
			if (b) {
				mc.btn.gotoAndStop(2)
				mc.play()
				mc.belt0.play()
				mc.belt1.play()
				a.play (SoundManager.EFFECTS_PATH +"gears_14_loop.mp3",true)
			} else {
				mc.btn.gotoAndStop(1)
				mc.stop()
				mc.belt0.stop()
				mc.belt1.stop()
				a.stop(	SoundManager.EFFECTS_PATH +"gears_14_loop.mp3")
			}
		}
		
		private function setupHydraulicsAndCar():void
		{
			var i:int;
			var spatial:Spatial;
			var target:FollowTarget;
			
			_hydraulics = new Vector.<Entity>
			
			var hydraulic:Entity;
			var btnToRaise:Entity
			var btnToLower:Entity
			var audio:Audio;
			
			var h:HydraulicDirection;
			
			// Only set up second hydraulic lift if it's night
			var iMax:int = 2
			
			for (i =0 ; i < iMax; i++) {
				hydraulic = EntityUtils.createSpatialEntity(this, this._hitContainer["hydraulic"+i]);
				hydraulic.add(new Id("hydraulic"+i));
				hydraulic.add(new Tween());
				
				_hydraulics.push(hydraulic)
				h = new HydraulicDirection();
				h.min = [620,493][i];
				h.max = 820;
				
				hydraulic.add(h);
				
				var sp:Spatial = hydraulic.get(Spatial);
				
				btnToRaise = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnToRaise_"+i]), this);
				btnToRaise.remove(Timeline);
				//btnToRaise.get(Interaction).down.add( Command.create( onHydraulicBtnToRaiseMouseUp ));
				btnToRaise.get(Interaction).upNative.add( Command.create( onHydraulicBtnToRaiseMouseUp ));
				Display(btnToRaise.get(Display)).isStatic = false;
				
				btnToLower = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["btnToLower_"+i]), this);
				btnToLower.remove(Timeline);
				//btnToLower.get(Interaction).down.add( Command.create( onHydraulicBtnToLowerMouseUp ));
				btnToLower.get(Interaction).upNative.add( Command.create( onHydraulicBtnToLowerMouseUp ));
				
				Display(btnToLower.get(Display)).isStatic = false;
				
				audio = new Audio();
				hydraulic.add (audio)
				//Hydraulic platforms. NOTE: entities with "HitPlatform" in their instance name will automatically be created 
				var hit:Entity = this.getEntityById("hydraulicHitPlatform"+i);
				
				Display(hit.get(Display)).isStatic = false;
				spatial = hit.get(Spatial);
				
				target = new FollowTarget(sp);
				target.offset = new Point(spatial.x - sp.x, spatial.y - sp.y);
				hit.add(target);
			}
			
			_car = EntityUtils.createSpatialEntity(this, this._hitContainer["car"]);
			
			if (this.shellApi.checkEvent(_events.SET_NIGHT)){
				
			} else {
				// follow platform. Note this is only to have it bounce a bit when user tries to move it but can't. Otherwise it's invisible.
				spatial = _hydraulics[1].get(Spatial)
				target = new FollowTarget(sp);
				target.offset = new Point(0, -100);
				_car.add(target);
			}
			
			_hydraulicMoverSystem  = new HydraulicMoverSystem
			addSystem(_hydraulicMoverSystem)
		}
		
		private function onHydraulicBtnToRaiseMouseUp (event:Event):void {
			var n:int = (event.target.name.split("_")[1])
			//trace ("onHydraulicBtnToRaiseMouseUp:" + event.target.name + "  n:" + n)
			var h:Entity = _hydraulics[n]
			if (h.get(HydraulicDirection).tweening) return
			var audio:Audio = h.get(Audio)
			if (n==1 && !this.shellApi.checkEvent(_events.SET_NIGHT) && !this.shellApi.checkHasItem(_events.MEDAL_CARNIVAL))  {
				var t:Number = .3
				super.getEntityById("marnie").get(Dialog).sayById("useLiftWhenCarPresent");
				var sp:Spatial = h.get(Spatial)
				Tween(h.get(Tween)).to(sp,t,{y:sp.y -30,ease:Sine.easeInOut, yoyo:true, repeat:1, onComplete:setToNotTweening, onCompleteParams:[h]})
				audio.play(SoundManager.EFFECTS_PATH + "gears_01.mp3", false)
				h.get(HydraulicDirection).tweening = true
				//SceneUtil.addTimedEvent(this, new TimedEvent(t*2,1,stopHydraulicSound));
			} else {
				h.get(HydraulicDirection).direction = -1
			}
			audio.play(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3", true)
		}
		
		private function onHydraulicBtnToLowerMouseUp (event:Event):void {
			var n:int = (event.target.name.split("_")[1])
			var h:Entity = _hydraulics[n]
					
			if (h.get(HydraulicDirection).tweening) return
			var audio:Audio = h.get(Audio)
			
			// Second lift only usable at night
			if (n==1 && !this.shellApi.checkEvent(_events.SET_NIGHT) && !this.shellApi.checkHasItem(_events.MEDAL_CARNIVAL))  {
				var t:Number = .3
				super.getEntityById("marnie").get(Dialog).sayById("useLiftWhenCarPresent");
				var sp:Spatial = h.get(Spatial)
				Tween(h.get(Tween)).to(sp,t,{y:sp.y + 30,ease:Sine.easeInOut, yoyo:true, repeat:1, onComplete:setToNotTweening, onCompleteParams:[h]})
				h.get(HydraulicDirection).tweening = true
				audio.play(SoundManager.EFFECTS_PATH + "gears_01.mp3", false)
			} else {
				h.get(HydraulicDirection).direction = 1 
				audio.play(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3", true)
			}
		}
		
		private function setToNotTweening (h:Entity):void {
			h.get(HydraulicDirection).tweening = false
		}
		
		//		private function onHydraulicBtnUp (e:Entity):void {
		//			var n:int = int (event.target.name.split("_")[1])
		//			trace ("onHydraulicBtnUp:" + event.target.name + "  n:" + n)
		//			var h:Entity = _hydraulics[n]
		//			h.get(HydraulicDirection).direction = 0
		//			var audio:Audio = h.get(Audio)
		//			audio.stop(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3")
		//		}
		
		private function stopHydraulicSound (e:Entity=null):void {
			for each (var h:Entity in _hydraulics) {
				var audio:Audio = h.get(Audio)
				audio.stop(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3")
				audio.play(SoundManager.EFFECTS_PATH + "gears_01.mp3", false)
			}
		}
		
		private function lockControl():void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl():void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
		
	}
}



