package game.scenes.survival2.unfrozenLake
{
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.timeline.Timeline;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Stand;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival2.shared.Survival2Scene;
	import game.scenes.survival2.shared.components.Hookable;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class UnfrozenLake extends Survival2Scene
	{
		private var _events:Survival2Events;
		private var _treebtn1:Entity;
		private var _treebtn2:Entity;	
		private var _treebtn3:Entity;	
		private var _tree_tip1:Entity;
		private var _tree_tip2:Entity;
		private var _tree_tip3:Entity;
		private var _camerafollow:Entity;
		private var _boot_btn:Entity;
		
		public function UnfrozenLake()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival2/unfrozenLake/";
			//super.showHits = true;
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
			
			setupLakeWater();
			setUpZones();
			setUpAnimations();			
			checkEventsComplete();	
			setupBranches()

		}
		
		private function setupLakeWater():void
		{
			var bitmap:Bitmap = this.createBitmap(this._hitContainer["lake"]);
			DisplayUtils.moveToTop(bitmap);
		}
		
		private function setupBranches():void{
			var entity:Entity;
			var timeline:Timeline;
			
			for (var i:Number = 0; i <= 1; i++){
				
				var clip:MovieClip = MovieClip(super._hitContainer)["branch" + i];
				var bounceEntity:Entity = super.getEntityById( "bounce" + i );
				
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
				
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			}
		}
		
		private function setUpZones():void{
			var treeZoneEntity:Entity = super.getEntityById( "treeZone" );			
			var treeZone:Zone = treeZoneEntity.get( Zone );
			treeZone.pointHit = true;
			treeZone.entered.add(hideTree);
			treeZone.exitted.add(showTree);
			
			//_waterZoneEntity = super.getEntityById( "freezeZone" );			
			//waterZone = _waterZoneEntity.get( Zone );
			//waterZone.pointHit = true;
			//waterZone.entered.add(freezePlayer);
		}
		
		private function hideTree(zoneID:String, colliderID:String):void{
			if(colliderID == "player"){
				MovieClip(super._hitContainer).tree_mc.visible = false;
			}else if (colliderID == "fishingHook"){
				var holePlatform:Entity = super.getEntityById("holePlatform");
				holePlatform.remove(Platform);
			}
		}
		
		private function showTree(zoneID:String, colliderID:String):void{			
			if(colliderID == "player"){
				MovieClip(super._hitContainer).tree_mc.visible = true;
			}
		}
		
		/*private function freezePlayer(zoneID:String, colliderID:String):void{			
			if(colliderID == "player"){
				addChildGroup( new FreezePopup( overlayContainer ));
			}
		}*/
		
		private function setUpAnimations():void
		{
			var clip:MovieClip;
			
			_camerafollow = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).camerafollow ) );
			
			clip = this._hitContainer["tree_tip1_mc"];
			_tree_tip1 = EntityUtils.createSpatialEntity( this, clip );
			this.convertContainer(clip);
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).tree_tip1_mc ), this, _tree_tip1, null, false );
			Timeline(_tree_tip1.get(Timeline)).gotoAndStop("starting");			
			_tree_tip1.get(Timeline).handleLabel( "tipping", treeTipping, true  );
			_tree_tip1.get(Timeline).handleLabel( "hitground", Command.create(treeHit, 1), true  );
			_tree_tip1.get(Timeline).handleLabel( "ended", pushedTree, true  );
			
			clip = this._hitContainer["tree_tip2_mc"];
			_tree_tip2 = EntityUtils.createSpatialEntity( this, clip );
			this.convertContainer(clip);
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).tree_tip2_mc ), this, _tree_tip2, null, false );
			Timeline(_tree_tip2.get(Timeline)).gotoAndStop("starting");			
			_tree_tip2.get(Timeline).handleLabel( "tipping", treeTipping, true  );
			_tree_tip2.get(Timeline).handleLabel( "hitground", Command.create(treeHit, 2), true  );
			_tree_tip2.get(Timeline).handleLabel( "ended", pushedTree, true  );
			
			clip = this._hitContainer["tree_tip3_mc"];
			_tree_tip3 = EntityUtils.createSpatialEntity( this, clip );
			this.convertContainer(clip);
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).tree_tip3_mc ), this, _tree_tip3, null, false );
			Timeline(_tree_tip3.get(Timeline)).gotoAndStop("starting");			
			_tree_tip3.get(Timeline).handleLabel( "tipping", treeTipping, true  );
			_tree_tip3.get(Timeline).handleLabel( "hitground", Command.create(treeHit, 3), true  );
			_tree_tip3.get(Timeline).handleLabel( "ended", pushedTreeRaft, true  );
			
			clip = this._hitContainer["owl_mc"];
			var owl:Entity = EntityUtils.createSpatialEntity( this, clip );
			this.convertContainer(clip, 1);
			TimelineUtils.convertClip( clip , this, owl, null, true );
			var interaction:Interaction = InteractionCreator.addToEntity(owl, ["click"], clip);
			interaction.click.add(handleOwlButtonClicked);
			ToolTipCreator.addToEntity(owl, ToolTipType.CLICK, null, new Point(clip.width / 2, clip.height / 2));
			
			MovieClip(super._hitContainer).raftPlatform.alpha = 0;
			
		}
		
		private function createInteraction(clip:MovieClip, method:Function):Entity
		{
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var interaction:Interaction = InteractionCreator.addToEntity(entity, ["click"], clip);
			interaction.click.add(method);
			ToolTipCreator.addToEntity(entity);
			return entity;
		}
		
		private function checkEventsComplete():void{
			
			if (this.shellApi.checkEvent(_events.LAKE_TREE1_DOWN)){
				Timeline(_tree_tip1.get(Timeline)).gotoAndStop("ended");	
			}else{
				var tree0platform:Entity = super.getEntityById("tree0platform");
				tree0platform.remove(Platform);
				//_treebtn1 = ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).treebtn1, this, Command.create(handleTreeButtonCicked, 1, 5050, 1300), null, null, ToolTipType.CLICK);
				_treebtn1 = createInteraction(_hitContainer["treebtn1"],Command.create(handleTreeButtonCicked, 1, 5050, 1300));
			}
			if (this.shellApi.checkEvent(_events.LAKE_TREE2_DOWN)){
				Timeline(_tree_tip2.get(Timeline)).gotoAndStop("ended");	
			}else{
				var tree1platform:Entity = super.getEntityById("tree1platform");
				var tree2platform:Entity = super.getEntityById("tree2platform");
				tree1platform.remove(Platform);
				tree2platform.remove(Platform);
				//_treebtn2 = ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).treebtn2, this, Command.create(handleTreeButtonCicked, 2, 4605, 1200), null, null, ToolTipType.CLICK);
				_treebtn2 = createInteraction(_hitContainer["treebtn2"],Command.create(handleTreeButtonCicked, 2, 4605, 1200));
			}
			if (this.shellApi.checkEvent(_events.LAKE_RAFT_DOWN)){
				setUpRaft();
			}else{
				var raftPlatform:Entity = super.getEntityById("raftPlatform");
				raftPlatform.remove(Platform);
				//_treebtn3 = ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).treebtn3, this, Command.create(handleTreeButtonCicked, 3, 3825, 770), null, null, ToolTipType.CLICK);
				_treebtn3 = createInteraction(_hitContainer["treebtn3"],Command.create(handleTreeButtonCicked, 3, 3825, 770));
			}
			
			if (this.shellApi.checkHasItem(_events.SHOELACE2) || shellApi.checkItemUsedUp(_events.SHOELACE2)){
				this._hitContainer["shoelace"].visible = false;
			}else{				
				setupShoelace();
				//_boot_btn = ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).boot_btn, this, handleBootButtonClicked, null, null, ToolTipType.CLICK);
				_boot_btn = createInteraction(_hitContainer["boot_btn"],handleBootButtonClicked);
			}
			if (this.shellApi.checkHasItem(_events.SHOELACE1) || shellApi.checkItemUsedUp(_events.SHOELACE2)){
				removeEntity(getEntityById("shoelace1"));
			}
		}
		
		private function handleBootButtonClicked(entity:Entity):void	
		{
			Dialog(player.get(Dialog)).sayById("getBoot");			
		}
		
		private function handleOwlButtonClicked(entity:Entity):void	
		{
			super.shellApi.triggerEvent("owl");
			Timeline(entity.get(Timeline)).gotoAndPlay("wakeup");
		}
		
		private function handleTreeButtonCicked(entity:Entity, id, x, y):void	
		{			
			lockControl();
			CharUtils.moveToTarget(player, x, y, false, Command.create(pushTree, id, x, y));
		}
		
		private function pushTree(entity:Entity, id, x, y):void{
			CharUtils.setDirection(player, false);
			player.get(Spatial).x = x;
			player.get(Spatial).y = y;
			SceneUtil.addTimedEvent( this, new TimedEvent( .4, 1, Command.create(startPushTree, id) ));	
		}
		
		private function startPushTree(id):void{
			CharUtils.setAnim( super.player, Push, false );			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create(startTreeTip, id) ));				
		}
		
		private function treeHit(id):void{
			if (id == 1) super.shellApi.triggerEvent("loghitsnow");
			if (id == 2) super.shellApi.triggerEvent("loghittree");
			if (id == 3) super.shellApi.triggerEvent("loghitwater");
		}
		
		private function startTreeTip(id):void{	
			super.shellApi.triggerEvent("treetip");
			if (id == 1) Timeline(_tree_tip1.get(Timeline)).play();
			if (id == 2) Timeline(_tree_tip2.get(Timeline)).play();
			if (id == 3){ 
				Timeline(_tree_tip3.get(Timeline)).play(); 
				TweenUtils.entityTo(_camerafollow, Spatial, 2,{x:3236, y:1580, delay:2, ease:Linear.easeIn});
				SceneUtil.setCameraTarget(this, _camerafollow); 
			}
			createTreeHits(id);
		}
		
		private function treeTipping(...args):void{			
			CharUtils.setAnim( super.player, Stand, false );
		}
		
		private function pushedTree(...args):void{			
			CharUtils.stateDrivenOn(this.player);
			restoreControl();
		}
		
		private function pushedTreeRaft(...args):void{			
			pushedTree();			
			setUpRaft();
			super.removeEntity(_treebtn3);
		}
		
		private function createTreeHits(id):void{
			var entity:Entity;
			var creator:HitCreator = new HitCreator();
			var audioGroup:AudioGroup = getGroupById( "audioGroup" ) as AudioGroup;
			
			if (id == 1){
				var tree0platform:Entity = super.getEntityById("tree0platform");				
				tree0platform.add(new Platform());
				super.removeEntity(_treebtn1);
				super.shellApi.triggerEvent(_events.LAKE_TREE1_DOWN, true);	
			}else{
				var tree1platform:Entity = super.getEntityById("tree1platform");
				var tree2platform:Entity = super.getEntityById("tree2platform");
				var wall1:Entity = super.getEntityById("wall1");
				tree1platform.add(new Platform());
				tree2platform.add(new Platform());
				super.removeEntity(_treebtn2);
				super.shellApi.triggerEvent(_events.LAKE_TREE2_DOWN, true);	
			}
		}
		
		private function setUpRaft():void{
			
			_tree_tip3.get(Display).visible = false;
			
			var raftPlatform:Entity = super.getEntityById("raftPlatform");
			raftPlatform.add(new Platform());			
				
			var movingHitData:MovingHitData = new MovingHitData();
			//movingHitData.visible = "raftArt";  // map this to a 'visible' movieclip in the scene.
			
			var audioGroup:AudioGroup = getGroupById( "audioGroup" ) as AudioGroup;
			var treeRaft:Entity;
			var creator:HitCreator = new HitCreator();
			
			treeRaft = EntityUtils.createSpatialEntity( this, _hitContainer[ "raftPlatform" ]);
			treeRaft.add( new Id( "treeRaft" ));
			treeRaft.add( new Sleep( true, false ) );
			creator.makeHit( treeRaft, HitType.MOVING_PLATFORM, movingHitData, this);
			creator.addHitSoundsToEntity( treeRaft, audioGroup.audioData, shellApi );
			
			var motion:Motion = treeRaft.get(Motion);
			motion.friction = new Point(0, 0);
			motion.maxVelocity = new Point(400, 400);
			
			var raftMoverSystem:RaftMoverSystem = new RaftMoverSystem;
			raftMoverSystem.init(treeRaft, player);
			
			super.addSystem( raftMoverSystem, SystemPriorities.update );
			super.shellApi.triggerEvent(_events.LAKE_RAFT_DOWN, true);				
			SceneUtil.setCameraTarget(this, player);
			
		}
		
		private function setupShoelace():void
		{
			var clip:MovieClip = this._hitContainer["shoelace"];
			var shoelace:Entity = EntityUtils.createMovingEntity(this, clip);
				
			shoelace.add(new SpatialAddition());
			shoelace.add(new Id("shoelace"));
								
			var hookable:Hookable = new Hookable();
			hookable.bait = "any";
			hookable.remove = true;
			hookable.offsetX = 0;
			hookable.offsetY = 0;
			hookable.reeling.add(this.onShoelaceReeling);
			hookable.reeled.add(this.onShoelaceReeled);
			shoelace.add(hookable);

		}		
		
		private function onShoelaceReeling(hookableEntity:Entity, hookEntity:Entity):void
		{
			SceneUtil.lockInput(this);
			MotionUtils.zeroMotion(hookableEntity);			
			
			var spatial:Spatial = hookableEntity.get(Spatial);
			spatial.rotation = 90;
			if(spatial.scaleX < 0)
			{
				spatial.scaleX *= -1;
			}
		}
		
		private function onShoelaceReeled(hookableEntity:Entity, hookEntity:Entity):void
		{
			SceneUtil.lockInput(this, false);	
			var holePlatform:Entity = super.getEntityById("holePlatform");
			holePlatform.add(new Platform());
			super.shellApi.getItem( _events.SHOELACE2, null, true );
			super.removeEntity(_boot_btn); 
		}
		
		private function lockControl():void
		{
			MotionUtils.zeroMotion(super.player, "x");
			MotionUtils.zeroMotion(super.player, "y");
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


