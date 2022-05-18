package game.scenes.prison.hill
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Ceiling;
	import game.components.hit.Platform;
	import game.components.hit.ValidHit;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.Wave;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.cellBlock.CellBlock;
	import game.scenes.prison.tower.popups.NewspaperPopup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class Hill extends PrisonScene
	{
		private var police1:Entity;
		private var police2:Entity;
		private var tex:Entity;
		private var bandit:Entity;
		private var sal:Entity;
		private var les:Entity;
		private var can:Entity;
		
		private var p1:Entity;
		private var p2:Entity;
		private var p3:Entity;
		private var p4:Entity;
		private var p5:Entity;
		private var p6:Entity;
		
		private var insideBuilding:Boolean = false;
		
		private var money:Entity;
		
		private var triggerCrate:TriggerHit;
		private var triggerHit:TriggerHit;
		
		private var cover:Entity;
		
		public function Hill()
		{
			this.mergeFiles = true;
			super();
		}
		
		override public function destroy():void
		{
			p1 = null;
			p2 = null;
			p3 = null;
			p4 = null;
			p5 = null;
			p6 = null;
			police1 = null;
			police2 = null;
			tex = null;
			bandit = null;
			sal = null;
			les = null;
			can = null;
			money = null;
			cover = null;
			triggerCrate = null;
			
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/hill/";
			
			super.init(container);
			//super.showHits = true;
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
			
			police1 = this.getEntityById("police1");
			police2 = this.getEntityById("police2");
			tex = this.getEntityById("tex");
			bandit = this.getEntityById("bandit");
			
			ToolTipCreator.removeFromEntity(tex);
			ToolTipCreator.removeFromEntity(bandit);
			ToolTipCreator.removeFromEntity(police2);
			ToolTipCreator.removeFromEntity(police1);
			
			if(this.shellApi.checkHasItem(_events.MEDAL_PRISON)) {
				if(this.getEntityById("police1"))
					this.removeEntity(this.getEntityById("police1"));
				if(this.getEntityById("police2"))
					this.removeEntity(this.getEntityById("police2"));
				if(this.getEntityById("tex"))
					this.removeEntity(this.getEntityById("tex"));
				if(this.getEntityById("bandit"))
					this.removeEntity(this.getEntityById("bandit"));
				if(this.getEntityById("p1"))
					this.removeEntity(this.getEntityById("p1"));
				if(this.getEntityById("p2"))
					this.removeEntity(this.getEntityById("p2"));
				if(this.getEntityById("p3"))
					this.removeEntity(this.getEntityById("p3"));
				if(this.getEntityById("p4"))
					this.removeEntity(this.getEntityById("p4"));
				if(this.getEntityById("p5"))
					this.removeEntity(this.getEntityById("p5"));
				if(this.getEntityById("p6"))
					this.removeEntity(this.getEntityById("p6"));
				if(this.getEntityById("les"))
					this.removeEntity(this.getEntityById("les"));
				if(this.getEntityById("sal"))
					this.removeEntity(this.getEntityById("sal"));
				setupTrashCan();
				if(this.getEntityById("wire")){
					var hit:Entity = this.getEntityById("wire");
					hit.remove(Platform);
				}
				
				var door:Entity = super.getEntityById("doorWarehouse");
				var interaction:Interaction = door.get(Interaction);
				interaction.click = new Signal();
				interaction.click.add(sayNoEnter);	
				
				this.getEntityById("d1").remove(Wall);
				this.getEntityById("d2").remove(Platform);
				this.getEntityById("d3").remove(Platform);
				
			} else if(this.shellApi.checkEvent(_events.PLAYER_ESCAPED)) {
				setupTrashCan();
				setupWarehouseDoor();
				
				sal = this.getEntityById("sal");
				les = this.getEntityById("les");
				if(!this.shellApi.checkEvent(_events.SAW_LES_SAL)){
					Dialog(les.get(Dialog)).faceSpeaker = false;
					Dialog(sal.get(Dialog)).faceSpeaker = false;
					SceneUtil.lockInput(this, true);
					this.shellApi.camera.target = can.get(Spatial);
					CharUtils.moveToTarget(sal, 1600, 671, false, setSal);
					CharUtils.moveToTarget(les, 1680, 671, false, setLes);
				} else {
					this.removeEntity(les);
					this.removeEntity(sal);
					setupZones();
				}
				
				if(this.getEntityById("bandit")){
					this.removeEntity(bandit);
				}
				if(this.getEntityById("tex")){
					tex.get(Spatial).x = 987;
					tex.get(Spatial).y = 2610;
					CharUtils.setDirection(tex, false);
				}
				
				if(player.get(Spatial).y > 2000){
					player.get(Spatial).x = 1780; 
					player.get(Spatial).y = 2921;
					CharUtils.setDirection(player, false);
				}
				
				p1 = this.getEntityById("p1");
				p2 = this.getEntityById("p2");
				p3 = this.getEntityById("p3");
				p4 = this.getEntityById("p4");
				p5 = this.getEntityById("p5");
				p6 = this.getEntityById("p6");
				
				this.addSystem( new TriggerHitSystem());
				
				var wireFloor:Entity = this.getEntityById("wireFloor");
				wireFloor.remove(Platform);
				var wirePlank:Entity = this.getEntityById("wirePlank");
				wirePlank.remove(Platform);
				
				var crate:Entity = getEntityById( "crate" );
				triggerCrate = new TriggerHit( null, new <String>[ "player" ]);
				triggerCrate.triggered = new Signal();
				crate.add( triggerCrate );
				
				var triggerPlatform:Entity = getEntityById( "triggerPlat2" );
				triggerHit = new TriggerHit( null, new <String>[ "player" ]);
				triggerHit.triggered = new Signal();
				triggerPlatform.add( triggerHit );
				
			} else if (this.shellApi.checkEvent(_events.SAW_BANDIT) && !this.shellApi.checkEvent(_events.CAPTURED_PLAYER)) {
				Dialog(player.get(Dialog)).sayById("there");
				CharUtils.setAnim(player, game.data.animation.entity.character.PointItem);
				
			} else if (!this.shellApi.checkEvent(_events.SAW_BANDIT)){
				this.removeEntity(this.getEntityById("bandit"));
			}
			setupMoney();
			setupBandit();
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "start_run" ) {
				startBanditRun1();
			} else if( event == "betrayal" ) {
				bandit.get(Display).visible = true;
				CharUtils.moveToTarget(bandit, 1660, 655, false, catchPlayer);
			} else if( event == "stand_up" ) {
				CharUtils.setAnim(player, game.data.animation.entity.character.Stand);
			} else if( event == "remove_mask" ){
				CharUtils.setAnim(bandit, Wave);
				SceneUtil.addTimedEvent(this, new TimedEvent(0.3, 1, removeMask, true));
			} else if( event == "double" ) {
				super.shellApi.camera.target = tex.get(Spatial);
				CharUtils.moveToTarget(tex, 150, 2968, false, texEnter);
				CharUtils.moveToTarget(police1, 90, 2968, false);
				CharUtils.moveToTarget(police2, 70, 2968, false);
			} else if( event == "fan_out" ) {
				super.shellApi.camera.target = player.get(Spatial);
				Dialog(bandit.get(Dialog)).sayById("enjoy");
			} else if( event == "bandit_out" ) {
				//CharUtils.moveToTarget(bandit, 482, 900, false, removeBandit);
				CharUtils.moveToTarget(bandit, 1890, 655, false, removeBandit);
			} else if( event == "capture" ) {
				this.shellApi.completeEvent(_events.CAPTURED_PLAYER);
				shellApi.takePhotoByEvent("sent_to_jail_photo", openNewspaperPopup);
			} else if( event == "sal_les_out" ) {
				CharUtils.moveToTarget(sal, 482, 900, false);
				CharUtils.moveToTarget(les, 482, 900, false, removeSalLes);
			} else if( event == "manhunt" ) {
				setupZones();
			}
		}
		
		private function openNewspaperPopup():void {
			var newspaperPopup:NewspaperPopup = new NewspaperPopup(overlayContainer);
			addChildGroup(newspaperPopup);
			SceneUtil.lockInput(this, false);
			newspaperPopup.popupRemoved.addOnce(newspaperPopupClosed);
		}
		
		private function newspaperPopupClosed():void {
			SceneUtil.lockInput(this, true);
			this.shellApi.loadScene(CellBlock, 600, 970, "right");
		}
		
		private function removeMask():void {
			// create a new LookData class
			var lookData2:LookData = new LookData();
			lookData2.applyAspect( SkinUtils.getLookAspect(player, SkinUtils.SKIN_COLOR) );
			lookData2.applyAspect( SkinUtils.getLookAspect(player, SkinUtils.HAIR) );
			lookData2.applyAspect( SkinUtils.getLookAspect(player, SkinUtils.HAIR_COLOR) );
			lookData2.applyAspect( SkinUtils.getLookAspect(player, SkinUtils.MARKS) );
			lookData2.applyAspect( new LookAspectData( SkinUtils.FACIAL, "empty" ) );
			
			SkinUtils.applyLook( bandit, lookData2, false );
		}
		
		private function removeSalLes(entity:Entity):void {
			this.removeEntity(sal);
			this.removeEntity(les);
			this.shellApi.completeEvent(_events.SAW_LES_SAL);
			runManhunt();
		}
		
		private function setSal(entity:Entity):void {
			CharUtils.setDirection(sal, true);			
		}
		
		private function setLes(entity:Entity):void {
			Dialog(les.get(Dialog)).sayById("vamoose");
			CharUtils.setDirection(les, false);
		}
		
		private function runManhunt():void {
			this.shellApi.camera.target = tex.get(Spatial);
			Dialog(tex.get(Dialog)).sayById("listen_up");
		}
		
		private function setupZones():void {
			var zone0:Zone = getEntityById("zone0").get(Zone);
			zone0.entered.add(enterZone);
			zone0.pointHit = true;//if you have a big hat on can cause issues
			//zone0.exitted.add(exitZone);
			
			var zone1:Zone = getEntityById("zone1").get(Zone);
			zone1.entered.add(enterZone);
			zone1.pointHit = true;//if you have a big hat on can cause issues
			//zone1.exitted.add(exitZone);
			
			var zone2:Zone = getEntityById("zone2").get(Zone);
			zone2.entered.add(enterZone);
			zone2.pointHit = true;//if you have a big hat on can cause issues
			//zone2.exitted.add(exitZone);
			SceneUtil.lockInput(this, false);
			this.shellApi.camera.target = player.get(Spatial);
			Dialog(player.get(Dialog)).sayById("tower");
		}
		
		private function enterZone(zone:String, char:String):void
		{
			if(!_currentlyCaught) {
				SceneUtil.lockInput(this, true);
				
				if(zone == "zone0"){
					facePlayer(p1);
					Dialog(p1.get(Dialog)).sayById("stop");
					super.shellApi.camera.target = p1.get(Spatial);
				}
				if(zone == "zone1"){
					facePlayer(p5);
					Dialog(p5.get(Dialog)).sayById("stop");
					super.shellApi.camera.target = p5.get(Spatial);
				}
				if(zone == "zone2"){
					facePlayer(p6);
					Dialog(p6.get(Dialog)).sayById("stop");
					super.shellApi.camera.target = p6.get(Spatial);
				}
				
				caught();
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, fade, true));
				AudioUtils.play( this, SoundManager.MUSIC_PATH + "caught.mp3" );
				//setupWarehouseDoor();
			}
		}
		
		private function reload():void {
			this.shellApi.loadScene(Hill, 1780, 2921, "left");
		}
		
		private var _currentlyCaught:Boolean = false;
		
		private function caught(...args):void
		{
			if(!_currentlyCaught)
			{
				_currentlyCaught = true;
				SceneUtil.lockInput(this, true);			
				MotionUtils.zeroMotion(player);
				
				var fsm:FSMControl = player.get(FSMControl);			
				if(fsm.state.type == CharacterState.STAND)
				{
					finishCaught(CharacterState.STAND);
				}
				else
				{
					fsm.stateChange = new Signal();
					fsm.stateChange.add(finishCaught);
				}
			}
		}
		
		private function finishCaught(type:String, entity:Entity = null):void
		{
			if(type == CharacterState.STAND)
			{
				CharUtils.setAnim(player, Tremble);
				
				var fsmControl:FSMControl = player.get(FSMControl);
				if(fsmControl.stateChange)
				{
					fsmControl.stateChange.removeAll();
					fsmControl.stateChange = null;
				}
			}
		}
		
		private function fade():void {
			var screenEffects:ScreenEffects = new ScreenEffects(overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight, 1);
			screenEffects.fadeToBlack(2, sendPlayerBack, new Array(screenEffects));
		}
		
		private function sendPlayerBack(screenEffects:ScreenEffects = null):void
		{	
			
			var playerSpatial:Spatial = player.get(Spatial);
			playerSpatial.x = 1780;
			playerSpatial.y = 2921;			
			
			CharUtils.setAnim(player, Stand);
			CharUtils.setDirection(player, false);
			CharUtils.setDirection(p1, false);
			CharUtils.setDirection(p2, true);
			CharUtils.setDirection(p3, false);
			CharUtils.setDirection(p4, false);
			CharUtils.setDirection(p5, false);
			CharUtils.setDirection(p6, true);
			CharUtils.stateDrivenOn(player);
			CharUtils.setState(player, CharacterState.STAND);
			
			_currentlyCaught = false;
			
			super.shellApi.camera.target = player.get(Spatial);
			if(screenEffects)
			{
				screenEffects.fadeFromBlack(2, Command.create(SceneUtil.lockInput, this, false));
			}
		}
		
		private function facePlayer(entity:Entity):void {
			if(entity.get(Spatial).x > player.get(Spatial).x){
				CharUtils.setDirection(entity, true);
			} else {
				CharUtils.setDirection(entity, false);
			}
		}
		
		//bandit run 1
		private function startBanditRun1():void {
			super.shellApi.camera.target = bandit.get(Spatial);
			super.shellApi.camera.rate = 0.05;
			CharUtils.moveToTarget(bandit, 158, 1936, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, endBanditRun1, true));
		}
		
		private function endBanditRun1():void {
			super.shellApi.camera.target = player.get(Spatial);
			bandit.get(Spatial).x = 482;
			bandit.get(Spatial).y = 900;
			bandit.get(Display).visible = false;
			
			var playerThreshold:Threshold = new Threshold( "y", "<" );
			playerThreshold.threshold = 1980;
			playerThreshold.entered.addOnce( startBanditRun2 );
			player.add( playerThreshold );
			
			if( !super.systemManager.getSystem( ThresholdSystem )) {
				super.addSystem( new ThresholdSystem());
			}
		} // end bandit run 1
		
		//bandit run 2
		private function startBanditRun2():void {
			super.shellApi.camera.target = bandit.get(Spatial);
			bandit.get(Display).visible = true;
			bandit.get(Spatial).x = 482;
			bandit.get(Spatial).y = 900;
			CharUtils.moveToTarget(bandit, 1846, 655, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, endBanditRun2, true));
		}
		
		private function endBanditRun2():void {
			super.shellApi.camera.target = player.get(Spatial);
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, resetCameraRate, true));
			//playerThreshold.threshold = 685;
			//playerThreshold.entered.addOnce( startBanditBetrayal );
			
			bandit.get(Display).visible = false;
			CharUtils.setDirection(bandit, false);
			money.get(Display).visible = true;
		} // end bandit run 2
		
		
		private function betrayal2(entity:Entity):void {
			CharUtils.setDirection(player, false);
			Dialog(player.get(Dialog)).sayById("money");
		}
		
		private function catchPlayer(entity:Entity):void {
			SkinUtils.hideSkinParts(player, [SkinUtils.HEAD, SkinUtils.HAIR, SkinUtils.MARKS, SkinUtils.FACIAL, SkinUtils.MOUTH, SkinUtils.EYES, SkinUtils.HAND1, SkinUtils.HAND2, CharUtils.ARM_BACK, CharUtils.ARM_FRONT], true);
			CharUtils.getPart(player, CharUtils.MOUTH_PART).get(Display).alpha = 0;
			// create a new LookData class
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "empty" ) );
			SkinUtils.applyLook( bandit, lookData, false );
			
			var lookData2:LookData = new LookData();
			lookData2.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, "pr_sack" ) );
			SkinUtils.applyLook( player, lookData2, false );
			
			CharUtils.setAnim(player, game.data.animation.entity.character.Dizzy);
			Dialog(bandit.get(Dialog)).sayById("odds");
		}
		
		private function texEnter(entity:Entity):void {
			Dialog(tex.get(Dialog)).sayById("fan_out");
		}
		
		private function removeBandit(entity:Entity):void {
			this.removeEntity(bandit);
			tex.get(Spatial).x = 482;
			tex.get(Spatial).y = 900;
			police1.get(Spatial).x = 482;
			police1.get(Spatial).y = 900;
			police2.get(Spatial).x = 482;
			police2.get(Spatial).y = 900;
			CharUtils.moveToTarget(tex, 1546, 655, false, gotYou);
			CharUtils.moveToTarget(police1, 1690, 655, false, setLeft);
			CharUtils.moveToTarget(police2, 1720, 655, false, setLeft);
		} // end bandit betrayal
		
		//player capture
		private function gotYou(entity:Entity):void {
			Dialog(tex.get(Dialog)).sayById("got_you");
		}
		
		private function resetCameraRate():void {
			super.shellApi.camera.rate = 0.2;
		}
		
		private function setLeft(entity:Entity):void {
			CharUtils.setDirection(entity, false);
		}
		
		private function removeBuildingFront():void {
			SceneUtil.lockInput(this, false);
			EntityUtils.visible(cover, false);
			
			triggerHit.triggered.addOnce( replaceBuildingFront );
			
			triggerCrate.triggered.addOnce( walkToWindow );
			
			getEntityById("ceiling").add(new Ceiling());
			
			this.getEntityById("d1").add(new Wall());
			this.getEntityById("d2").add(new Platform());
			this.getEntityById("d3").add(new Platform());
		}
		
		private function replaceBuildingFront():void {
			EntityUtils.visible(cover);
			
			this.getEntityById("d1").remove(Wall);
			this.getEntityById("d2").remove(Platform);
			this.getEntityById("d3").remove(Platform);
			
			getEntityById("ceiling").remove(Ceiling);
			
			insideBuilding = false;
		}
		
		private function walkToWindow():void {
			CharUtils.moveToTarget(player, 1770, 1555, false);
		}
		
		private function setupTrashCan():void
		{
			var _sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
			
			super.addSystem(new SceneObjectHitRectSystem());
			
			super.player.add(new SceneObjectCollider());
			super.player.add(new RectangularCollider());
			super.player.add( new Mass(100) );
			
			var clip:MovieClip;
			var bounds:Rectangle;
			for (var i:int = 0; _hitContainer["box"+i] != null; i++) 
			{
				clip = _hitContainer["bounds"+i];
				bounds = new Rectangle(clip.x,clip.y,clip.width,clip.height);
				_hitContainer.removeChild(clip);
				clip = _hitContainer["box"+i] ;
				can = _sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x, clip.y,null,null,bounds,this,null,null,400);
				SceneObjectMotion(can.get(SceneObjectMotion)).rotateByPlatform = false;
				can.add(new Id("box"+i));
				can.add(new WallCollider());
				// box sounds
				var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
				audioGroup.addAudioToEntity(can, "can");
				new HitCreator().addHitSoundsToEntity(can,audioGroup.audioData,shellApi,"can");
				can.get(Platform).hitRect.y = -55;
			}
			var validHit:ValidHit = new ValidHit("boxWall");
			validHit.inverse = true;
			player.add(validHit);
		}
		
		private function setupMoney():void {
			if(_hitContainer["money"]){
				if(this.shellApi.checkEvent(_events.SAW_BANDIT)){
					money = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["money"]), this);
					money.remove(Timeline);
					money.get(Display).visible = false;
					var moneyInteraction:Interaction = money.get(Interaction);
					moneyInteraction.down.addOnce(clickMoney);
					
					ToolTipCreator.addToEntity( money );
					
				} else {
					_hitContainer["money"].visible = false;
				}
			}
		}
		
		private function clickMoney(money:Entity):void {
			SceneUtil.lockInput(this, true);
			CharUtils.moveToTarget(player, 1646, 655, false, betrayal2);
		}
		
		private function setupWarehouseDoor():void	{
			var door:Entity = super.getEntityById("doorWarehouse");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			interaction.click = new Signal();
			interaction.click.add(moveToDoor);	
			
			this.getEntityById("d1").remove(Wall);
			this.getEntityById("d2").remove(Platform);
			this.getEntityById("d3").remove(Platform);
			
			//setup building front
			var clip:MovieClip = _hitContainer["front"];
			this.convertContainer( clip );
			cover = EntityUtils.createSpatialEntity(this, clip);
		}
		
		private function moveToDoor(door:Entity=null):void {
			if(!insideBuilding){
				var targX:Number = door.get(Spatial).x;
				var targY:Number = door.get(Spatial).y-100;
				CharUtils.moveToTarget(player, targX, targY, false, openDoor);
				insideBuilding = true;
			}
		}
		
		private function openDoor(entity:Entity):void {
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, removeBuildingFront, true));
		}
		
		private function sayNoEnter(...p):void {
			Dialog(player.get(Dialog)).sayById("no_enter");
		}
		
		private function setupBandit():void {
			if(this.getEntityById("bandit")){
				var lookData:LookData = new LookData();
				lookData.applyAspect( SkinUtils.getLookAspect(player, SkinUtils.SKIN_COLOR) );
				SkinUtils.applyLook( bandit, lookData, false );
				
				var foot:Entity = Skin( bandit.get( Skin )).getSkinPartEntity( "foot1" );
				var footDisplay:Display = foot.get( Display );
				var boot1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["boot1"], footDisplay.displayObject);
				boot1.get(Spatial).scale = 3;
				boot1.get(Spatial).x = 0;
				boot1.get(Spatial).y = 0;
				
				var foot2:Entity = Skin( bandit.get( Skin )).getSkinPartEntity( "foot2" );
				var footDisplay2:Display = foot2.get( Display );
				var boot2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["boot2"], footDisplay2.displayObject);
				boot2.get(Spatial).scale = 3;
				boot2.get(Spatial).x = 0;
				boot2.get(Spatial).y = 0;
			}
		}
	}
}