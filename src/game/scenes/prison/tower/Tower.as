package game.scenes.prison.tower
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Angry;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.character.LookData;
	import game.scene.template.ItemGroup;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.hill.Hill;
	import game.scenes.prison.mainStreet.MainStreet;
	import game.scenes.prison.tower.popups.HeadshotsPopup;
	import game.scenes.prison.tower.popups.NewspaperPopup;
	import game.scenes.prison.tower.popups.PaintingPopup;
	import game.scenes.prison.tower.popups.SafePopup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class Tower extends PrisonScene
	{
		private var police1:Entity;
		private var police2:Entity;
		private var tex:Entity;
		private var bandit:Entity;
		private var safe:Entity;
		
		public function Tower()
		{
			this.mergeFiles = true;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/tower/";
			
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
			
			police1 = this.getEntityById("police1");
			police2 = this.getEntityById("police2");
			tex = this.getEntityById("tex");
			bandit = this.getEntityById("bandit");
			
			police1.get(Spatial).x = -100;
			police2.get(Spatial).x = -100;
			tex.get(Spatial).x = -100;
			bandit.get(Spatial).x = -100;
			
			if(!this.shellApi.checkHasItem(_events.MEDAL_PRISON)) {
				this.addSystem( new TriggerHitSystem());
				EntityUtils.lockSceneInteraction(getEntityById("safeInteraction"));
				var triggerPlatform:Entity = getEntityById( "triggerPlat" );
				var triggerHit:TriggerHit = new TriggerHit( null, new <String>[ "player" ]);
				triggerHit.triggered = new Signal();
				triggerHit.triggered.addOnce( sayDiscrepancy );
				triggerPlatform.add( triggerHit );
			} else {
				removeEntity(getEntityById("safeInteraction"));
			}
			
			setupSafe();
			setupFall();
			setupBird();
			setupBandit();
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "tex_enter" ) {
				texEnter();
			} else if ( event == "use_sharpened_spoon" ) {
				if(player.get(Spatial).y < 770) {
					
					var safeClick:Entity = getEntityById("safeInteraction");
					
					if(player.get(Spatial).x > safeClick.get(Spatial).x - 50 && player.get(Spatial).x < safeClick.get(Spatial).x){
						CharUtils.setDirection(player, true);
						sayPlaster();
					} else {
						SceneInteraction(safeClick.get(SceneInteraction)).activated = true;
					}
					ToolTipCreator.removeFromEntity(safeClick);
					ToolTipCreator.removeFromEntity(bandit);
					ToolTipCreator.removeFromEntity(tex);
					ToolTipCreator.removeFromEntity(police1);
					ToolTipCreator.removeFromEntity(police2);
				} else {
					Dialog(player.get(Dialog)).sayById("no_spoon");
				}
			} else if( event == "open_safe" ) {
				CharUtils.setDirection(player, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, openSafePopup, true));
			} else if( event == "opened_safe" ) {
				player.get(Spatial).x = 720;
				CharUtils.moveToTarget(bandit, 800, 731, false, showHeadshots);
			} else if( event == "at_last" ) {
				openHeadshotsPopup();
			} else if( event == "what" ) {
				CharUtils.setAnim(bandit, Grief);
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, sayYears, true));
			} else if( event == "years" ) {
				CharUtils.setAnim(bandit, Angry);
				Dialog(tex.get(Dialog)).sayById("confession");
			} else if( event == "take_away" ) {
				trace("Take Away");
				CharUtils.moveToTarget(police1, 845, 731, false, walkPrisoner);
				CharUtils.moveToTarget(police2, 845, 731, false);
			} else if( event == "bandit_captured" ) {
				CharUtils.setAnim(player, Laugh);
				CharUtils.setAnim(tex, Laugh);
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, releaseConversation, true));		
				this.shellApi.completeEvent(_events.BANDIT_CAPTURED);
			} else if( event == "release_prisoners" ) {
				trace("Release Prisoners");
				openNewspaperPopup();
			}
		}
		
		private function showEndingPopup():void
		{
			this.shellApi.getItem(_events.MEDAL_PRISON);
			SceneUtil.lockInput(this, false);
			//if (completionsUpdated) {
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
			islandEndPopup.popupRemoved.addOnce(endingPopupClosed);
			//completeIsland();
			//} else {
			//	endingPopupWaiting = true;
			//}
		}
		
		private function showHeadshots(entity:Entity):void {
			Dialog(bandit.get(Dialog)).sayById("at_last");
		}
		
		private function sayYears():void {
			Dialog(bandit.get(Dialog)).sayById("years");
		}
		
		private function openHeadshotsPopup():void {
			var headshotsPopup:HeadshotsPopup = new HeadshotsPopup(overlayContainer);
			addChildGroup(headshotsPopup);
			SceneUtil.lockInput(this, false);
			headshotsPopup.popupRemoved.addOnce(headshotsPopupClosed);
		}
		
		private function headshotsPopupClosed():void {
			SceneUtil.lockInput(this, true);
			Dialog(bandit.get(Dialog)).sayById("what");
		}
		
		private function openNewspaperPopup():void {
			var newspaperPopup:NewspaperPopup = new NewspaperPopup(overlayContainer);
			addChildGroup(newspaperPopup);
			SceneUtil.lockInput(this, false);
			newspaperPopup.popupRemoved.addOnce(newspaperPopupClosed);
		}
		
		private function newspaperPopupClosed():void {
			SceneUtil.lockInput(this, true);
			this.shellApi.loadScene(MainStreet, 3700, 1750, "left");
		}
		
		private function endingPopupClosed():void {
			SceneUtil.lockInput(this, true);
		}
		
		private function openedSafe():void {
			safe.get(Timeline).gotoAndStop(1);
			SceneUtil.lockInput(this, true);
			player.get(Spatial).x = 720;
			CharUtils.moveToTarget(bandit, 800, 731, false, showHeadshots);
			Dialog(bandit.get(Dialog)).sayById("at_last");
		}
		
		private function openSafePopup(...p):void {
			var safePopup:SafePopup = new SafePopup(overlayContainer);
			addChildGroup(safePopup);
			SceneUtil.lockInput(this, false);
			safePopup.removed.add(resetFromSafe);
		}
		
		private function resetFromSafe(popup:SafePopup):void {
			if(popup.safeOpened)
			{
				openedSafe();
				return;
			}
			
			CharUtils.lockControls(player);
			Dialog(player.get(Dialog)).allowOverwrite = true;
			Dialog(player.get(Dialog)).sayById("files");
			var interaction:SceneInteraction = getEntityById("safeInteraction").get(SceneInteraction);
			interaction.reached.removeAll();
			interaction.reached.add(openSafePopup);
		}
		
		private function safeIsOpen():void {
			safe.get(Timeline).gotoAndStop(1);
		}
		
		private function sayDiscrepancy():void {
			SceneUtil.lockInput(this, true);
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("different");
			dialog.complete.addOnce(readyToOpenPaninting);
		}
		
		private function readyToOpenPaninting(...args):void
		{
			SceneUtil.delay(this, 2, openPaintingPopup);
		}
		
		private function openPaintingPopup():void {
			var paintingPopup:PaintingPopup = new PaintingPopup(overlayContainer);
			addChildGroup(paintingPopup);
			SceneUtil.lockInput(this, false);
			paintingPopup.popupRemoved.addOnce(closePainting);
		}
		
		private function closePainting():void {
			SceneUtil.lockInput(this, false);
			this.shellApi.completeEvent(_events.SAW_DISCREPANCY);
			setupSafeButton();
		}
		
		private function setupSafeButton():void {
			var safeClick:Entity = getEntityById("safeInteraction");
			var interaction:SceneInteraction = safeClick.get(SceneInteraction);
			interaction.reached.add(sayPlaster);
			EntityUtils.lockSceneInteraction(safeClick, false);
		}
		
		private function sayPlaster(...args):void {
			CharUtils.setAnim(player, game.data.animation.entity.character.Place);
			Timeline(player.get(Timeline)).handleLabel("trigger2", openSafe);
			SceneUtil.lockInput(this, true);
			CharUtils.lockControls(player);
			Dialog(player.get(Dialog)).sayById("plaster");
			SceneInteraction(args[1].get(SceneInteraction)).reached.removeAll();
		}
		
		private function openSafe():void
		{
			var dialog:Dialog = player.get(Dialog);
			if(dialog.speaking)
				dialog.complete.addOnce(banditEnter);
			else
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, banditEnter, true));
			safe.get(Display).visible = true;
		}
		
		private function banditEnter(...args):void {
			//CharUtils.moveToTarget(player, 728, 731, false, setRight);
			CharUtils.setDirection(bandit, false);
			_hitContainer.addChild(_hitContainer["towerRight"]);
			_hitContainer.addChild(_hitContainer["towerLeft"]);
			bandit.get(Spatial).x = 1100;
			bandit.get(Spatial).y = 680;
			CharUtils.moveToTarget(bandit, 833, 731, false);
			Dialog(bandit.get(Dialog)).sayById("grunt_work");
			CharUtils.setDirection(player, true);
		}
		
		private function texEnter():void {
			tex.get(Spatial).x = 425;
			tex.get(Spatial).y = 680;
			
			CharUtils.moveToTarget(tex, 630, 731, false);
			CharUtils.setDirection(tex, true);
			CharUtils.setDirection(bandit, false);
			CharUtils.setDirection(player, false);
			Dialog(tex.get(Dialog)).sayById("got_you");
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, policeEnter, true));
		}
		
		private function policeEnter():void {
			CharUtils.setDirection(police1, false);
			police1.get(Spatial).x = 425;
			police1.get(Spatial).y = 680;
			CharUtils.moveToTarget(police1, 560, 731, false, movePoliceToPosition);			
			CharUtils.setDirection(police2, false);
			police2.get(Spatial).x = 425;
			police2.get(Spatial).y = 680;
			CharUtils.moveToTarget(police2, 560, 731, false, movePoliceToPosition);
		}
		
		private function movePoliceToPosition(entity:Entity):void {
			_hitContainer["towerLeft"].visible = false;
			if(entity == police1){
				CharUtils.moveToTarget(police1, 500, 731).setDirectionOnReached("right");
			}else{
				CharUtils.moveToTarget(police2, 460, 731).setDirectionOnReached("right");
			}
		}
		
		private function walkPrisoner(entity:Entity):void {
			CharUtils.moveToTarget(police1, 550, 731, false, policeLeave);
			CharUtils.moveToTarget(police2, 550, 731, false, policeLeave);
			CharUtils.moveToTarget(bandit, 540, 731, false, policeLeave);
		}
		
		private function policeLeave(entity:Entity):void {
			if(entity == bandit) {
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, medalionConversation, true));
				_hitContainer["towerLeft"].visible = true;
			}
			
			CharUtils.moveToTarget(entity, 425, 731, false, removeChars);
		}
		
		private function removeChars(entity:Entity):void {
			this.removeEntity(entity);
		}
		
		private function medalionConversation():void {
			Dialog(tex.get(Dialog)).sayById("long_time");
			CharUtils.setDirection(player, false);
		}
		
		private function releaseConversation():void {
			Dialog(tex.get(Dialog)).sayById("sorry");
		}
		
		private function setupSafe():void {
			var clip:MovieClip = _hitContainer["safe"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			safe = EntityUtils.createMovingTimelineEntity( this, clip );
			EntityUtils.visible(safe, false);
			safe.get(Timeline).gotoAndStop(0);
			
			var safeClick:Entity = getEntityById("safeInteraction");
			if(safeClick)
			{
				var interaction:SceneInteraction = safeClick.get(SceneInteraction);
				interaction.offsetDirection = false;
				interaction.minTargetDelta = new Point(25,100);
				interaction.offsetX = -100;
				interaction.faceDirection = "right";
			}
		}
		
		private function setupFall():void
		{
			var fallThreshold:Threshold = new Threshold( "y", ">" );
			fallThreshold.threshold = 2800;
			fallThreshold.entered.add( runFall );
			player.add( fallThreshold );
			if( !super.systemManager.getSystem( ThresholdSystem )) {
				super.addSystem( new ThresholdSystem());
			}
		}
		
		private function runFall():void {
			this.shellApi.loadScene(Hill, 1674, 4, "left");
		}
		
		private function setupBird():void {
			var seagull:Entity = EntityUtils.createMovingTimelineEntity(this, _hitContainer["seagull"],null,true);
			seagull.add(new Id("seagull"));
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(seagull));
			Timeline(seagull.get(Timeline)).handleLabel("squak",Command.create(birdSound,seagull),false);
			Timeline(seagull.get(Timeline)).handleLabel("endIdle",Command.create(testIdle,seagull),false);
		}
		
		private function testIdle(seagull:Entity):void {
			if(Math.random() < .33){
				Timeline(seagull.get(Timeline)).gotoAndPlay("squak");
			}
		}
		
		private function birdSound(seagull:Entity):void
		{
			AudioUtils.playSoundFromEntity(seagull, SoundManager.EFFECTS_PATH+"seagull_squawk_01.mp3");
		}
		
		private function setupBandit():void {
			if(this.getEntityById("bandit")){
				var foot:Entity = Skin( bandit.get( Skin )).getSkinPartEntity( "foot1" );
				var footDisplay:Display = foot.get( Display );
				var boot1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["boot1"], footDisplay.displayObject);
				boot1.get(Spatial).scale = 2.8;
				boot1.get(Spatial).x = -4;
				boot1.get(Spatial).y = -5;
				
				var foot2:Entity = Skin( bandit.get( Skin )).getSkinPartEntity( "foot2" );
				var footDisplay2:Display = foot2.get( Display );
				var boot2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["boot2"], footDisplay2.displayObject);
				boot2.get(Spatial).scale = 2.8;
				boot2.get(Spatial).x = -4;
				boot2.get(Spatial).y = -5;
				
				var playerLook:LookData = SkinUtils.getPlayerLook(this, true);
				SkinUtils.applyLook(bandit, playerLook, true);
			}
		}
	}
}