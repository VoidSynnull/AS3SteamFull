package game.scenes.lands.shared.systems {

	/**
	 * Controls the actual placement and destruction of land tiles in the scene.
	 */

	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.Skin;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.input.Input;
	import game.components.ui.Cursor;
	import game.creators.entity.AnimationSlotCreator;
	import game.data.animation.entity.character.BottleShake;
	import game.data.ui.ToolTipType;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.LandInventory;
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.classes.ResourceType;
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.components.FocusTileComponent;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.components.LandHiliteComponent;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.nodes.LandEditNode;
	import game.scenes.lands.shared.particles.GlitterEffect;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.ui.ScrollControl;
	import game.scenes.lands.shared.ui.panes.LandStatusPane;
	import game.util.CharUtils;
	
	import org.flintparticles.twoD.renderers.DisplayObjectRenderer;

	public class LandEditSystem extends System {

		/**
		 * time in seconds it takes to destroy a tile.
		 */
		private const TILE_DESTROY_TIME:Number = 0.25;
		/**
		 * time for character to pause after destroying a tile, before resuming navigation.
		 */
		private const MOVE_WAIT_FRAMES:Number = 10;
		
		/**
		 * Need to track the destroy target so the destroy time counter can reset when it changes.
		 */
		private var destroyTarget:LandTile;

		/**
		 * Display used for interpreting mouse clicks.
		 */
		private var clickDisplay:DisplayObject;

		private var editNodes:NodeList;

		/**
		 * There should only be ONE edit node at any given time so we can track it directly.
		 */
		private var masterNode:LandEditNode;
		private var editContext:LandEditContext;
		private var landGroup:LandGroup;
		private var glitterEffect:GlitterEffect;
		public function get EditEffect():GlitterEffect {
			return this.glitterEffect;
		}

		private var scrollControl:ScrollControl;

		/**
		 * true if this system is currently active -- in Edit or Mining mode.
		 */
		private var active:Boolean;

		private var expResource:ResourceType;
		private var popResource:ResourceType;

		/**
		 * the motion control of the player. used to freeze the player during editing/mining.
		 */
		//private var motionControl:MotionControl;

		/**
		 * status pane is used to update the poptanium/experiece displays without firing complex signals through the land inventory.
		 */
		private var statusPane:LandStatusPane;

		public function LandEditSystem( group:LandGroup, clickMask:DisplayObject ) {

			super();

			this.landGroup = group;
			var uiGroup:LandUIGroup = group.getUIGroup();
			this.statusPane = uiGroup.getStatusPane();
			this.scrollControl = uiGroup.getScrollControl();

			uiGroup.onUIModeChanged.add( this.onUIModeChanged );

			this.initHammerGlitter();

			this.statusPane = statusPane;
			this.clickDisplay = clickMask;

		} //

		override public function update( time:Number ):void {

			/**
			 * there should only be ONE land edit node. anything else is just wrong wrong wrong.
			 */
			var node:LandEditNode = this.editNodes.head;
			if ( node == null || node.entity.sleeping ) {
				return;
			}

			var context:LandEditContext = node.editContext;
			if ( context.isPainting == false ) {

				// test to unlock the character if he was frozen during mining.
				if ( context.curEditMode & LandEditMode.MINING ) {

					if ( node.focus.tile == null || node.focus.type == null ) {
						node.strikeTarget.enabled = false;
					} else {
						node.strikeTarget.enabled = true;
					}

					if ( context.charMoveDelay > 0 ) {
						if ( --context.charMoveDelay <= 0 ) {
							// messy, but better than it used to be, surprisingly.
							this.unlockPlayer();
						} //
					}

				} //

				return;

			} // NOT PAINTING

			if ( context.curEditMode & LandEditMode.EDIT ) {

				// the long function parameters below are just computing the min,max row,col bounds of the fill
				// based on the current brush rect.
				var hiliteRect:Rectangle = node.hilite.hiliteRect;

				if ( context.toggleDelete ) {

					// DELETE BRUSH AREA.
					if ( context.curTileMap.clearTypeRange(
						hiliteRect.y / context.curTileSize, hiliteRect.x / context.curTileSize,
						(hiliteRect.bottom)/ context.curTileSize, (hiliteRect.right) / context.curTileSize,
						context.curTileType.type ) > 0 ) {

						// tiles were cleared.
						node.audio.playCurrentAction( "erase" );
						context.curLayer.renderArea( hiliteRect );
						this.landGroup.gameData.sceneMustSave = true;

					} //

				} else {

					// for now, if a tile isn't editable but the user has it selected ( by special ability ), the price is free.
					var hasCost:Boolean = context.curTileType.allowEdit;
					var maxFills:int;
					if ( hasCost ) {

						maxFills = this.popResource.count;
						if ( maxFills <= 0 ) {
								
							// no poptanium.
							( this.group as LandGroup ).getUIGroup().showPoptaniumWarning();
							return;	
						} //

					} else {
						// no maximum.
						maxFills = 0xFFFFFF;
					} //

					// fill all tiles under the hilite ( which might be a large square ) and limit the number of by current poptanium count.
					var fillCount:int = context.curTileMap.fillRange( hiliteRect.y / context.curTileSize, hiliteRect.x / context.curTileSize,
						hiliteRect.bottom / context.curTileSize, hiliteRect.right / context.curTileSize,
						context.curTileType.type, maxFills );

					if ( fillCount > 0 ) {

						if ( hasCost ) {

							this.expResource.count += fillCount;
							this.popResource.count -= fillCount;

							this.statusPane.refresh();
						}

						this.landGroup.gameData.sceneMustSave = true;

						// tiles were filled.
						node.audio.playCurrentAction( "build" );
						context.curLayer.renderArea( hiliteRect );

					}

				} //

			} else if ( context.curEditMode & LandEditMode.MINING ) {

				//node.lightning.setTarget( this.clickDisplay.mouseX, this.clickDisplay.mouseY );

				var focus:FocusTileComponent = node.focus;
				context.charMoveDelay = this.MOVE_WAIT_FRAMES;

				if ( focus.tile == null || focus.type == null ) {

					// why would there be no focus tile? maybe if the cursor is offscreen?
					// focus type is null because nothing exists at the focused tile, or the type there doesn't allow mining.

				} else if ( focus.tile != this.destroyTarget ) {

					this.destroyTarget = focus.tile;
					// RESET the lightningTarget destroy timer.
					node.strikeTarget.resetStrikeTimer();

				} else {

					// Land destroy in progress: do a smaller blast.
					node.blaster.crumble( focus.type, this.clickDisplay.mouseX, this.clickDisplay.mouseY );
	
				} //

			} // mode == LandEditMode.MINING

		} // update()

		/**
		 * Lightning struck land target. Detroy the land at target location.
		 */
		private function onLightningStrike( hitEntity:Entity, lightning:LightningStrike ):void {

			var node:LandEditNode = this.editNodes.head;

			// don't need. target location will set automatically.
			//node.lightning.setTarget( this.clickDisplay.mouseX, this.clickDisplay.mouseY );
			
			var focus:FocusTileComponent = node.focus;
			node.editContext.charMoveDelay = this.MOVE_WAIT_FRAMES;

			if ( focus.tile == null || focus.type == null ) {

				// why would there be no focus tile? maybe if the cursor is offscreen?
				// focus type is null because nothing exists at the focused tile, or the type there doesn't allow mining.

			} else {

				// ERASE TILE / blast the current target.

				this.landGroup.gameData.sceneMustSave = true;

				// resets destroy time in case of multi-type tiles- new destroy-wait for each tile type.
				node.strikeTarget.resetStrikeTimer();
				node.blaster.addImmediate( new TileSelector( focus.tile, focus.type, node.editContext.curTileMap ) );

			} //

		} //

		/**
		 * called when the UI mode has changed. This is separate from the editing mode - since several editing modes
		 * fall under the same UI mode.
		 */
		private function onUIModeChanged( newMode:uint ):void {

			var input:Input = ( this.landGroup.shellApi.inputEntity.get( Input ) as Input );

			if ( this.editContext.isPainting ) {
				this.masterNode.audio.stopActionAudio( "magic" );
			} //

			if ( (newMode & LandEditMode.EDIT) || (newMode & LandEditMode.MINING) != 0 ) {

				if ( !this.active ) {
					this.active = true;
					input.inputUp.add( this.endPaint );
					input.inputDown.add( this.startPaint );
				}

				if ( (newMode & LandEditMode.MINING) != 0 ) {
					// enable lightning strikes.
					this.masterNode.strikeTarget.enabled = false;
				} else {
					this.masterNode.strikeTarget.enabled = true;
				}

			} else {

				this.masterNode.strikeTarget.enabled = false;

				if ( this.active ) {
					this.active = false;
					input.inputDown.remove( this.startPaint );
					input.inputUp.remove( this.endPaint );
				}

			}

		} //

		protected function startPaint( input:Input ):void {

			// if no tile has focus, there is nothing that can be edited/mined.
			var tile:LandTile = this.masterNode.focus.tile;
			if ( tile == null ) {
				return;
			}

			if ( this.editContext.curEditMode == LandEditMode.EDIT ) {

				this.doHammerAnimation();
				this.glitterEffect.start();

				this.masterNode.audio.playCurrentAction( "magic" );

				if ( this.editContext.curEditMode == LandEditMode.EDIT ) {
					
					if ( this.editContext.curTileMap == null || this.editContext.curTileType == null ) {
						return;
					}
					
					this.editContext.isPainting = true;
					
					if ( this.editContext.curTileMap.hasType( tile, this.editContext.curTileType.type ) ) {

						this.editContext.toggleDelete = true;

					} //
					
				} //
				
			} else if ( this.editContext.curEditMode & LandEditMode.MINING ) {

				if ( tile.type != LandTile.EMPTY ) {

					this.masterNode.hilite.hiliteBox.visible = true;

					this.lockPlayer();

					//this.masterNode.lightning.start();

					this.doHammerAnimation();

					this.editContext.isPainting = true;
					
				} else {
					
					this.editContext.isPainting = false;
					
				} //
				
			} // end-if.
			
		} // end startPaint()
		
		private function doHammerAnimation():void {

			var player:Entity = this.landGroup.getPlayer();

			// to layer animations, we will need another animation slot
			// first let's check if there is already an RigAnimation in the next slot, which would be 1.
			var rigAnim:RigAnimation = CharUtils.getRigAnim( player, 1 );
			
			// if there isn't an animation slot above our default then we add a new animation slot
			if ( rigAnim == null ) {

				// we create a new animation slot Entity using the AnimationSlotCreator
				// if a slot priority isn't specified it will add one to the next available slot
				var animationSlot:Entity = AnimationSlotCreator.create( player );

				// now that we have a new animation slot, let's get its RigAnimation so we can set it later.
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;

			} //
			
			rigAnim.next = BottleShake;
			//specify which parts the animation should apply to.
			rigAnim.addParts( CharUtils.HAND_FRONT, CharUtils.ARM_FRONT );

		} //

		public function isPainting():Boolean {
			return this.editContext.isPainting;
		}

		private function endPaint( input:Input ):void {

			if ( this.editContext.curEditMode == LandEditMode.EDIT ) {

				this.masterNode.audio.stopActionAudio( "magic" );
				this.landGroup.gameData.progress.tryLevelUp( this.expResource.count );
				this.statusPane.refresh();

				// force an update of the changed resources?
				this.masterNode.game.gameData.inventory.collectResource( this.popResource, 0 );
				this.masterNode.game.gameData.inventory.collectResource( this.expResource, 0 );

				this.glitterEffect.stop();

				//scroll to the painted area.
				if ( this.editContext.curTileType != null ) {

					var s:Spatial = this.scrollControl.getScrollSpatial();
					s.x = this.clickDisplay.mouseX;
					s.y = this.clickDisplay.mouseY;
					
				} //

			} //

			this.editContext.isPainting = false;
			this.editContext.toggleDelete = false;

			// stop the player hammer animation.
			var player:Entity = this.landGroup.getPlayer();
			var rigAnim:RigAnimation = CharUtils.getRigAnim( player, 1 );
			if ( rigAnim == null ) {
				var animationSlot:Entity = AnimationSlotCreator.create( player );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			rigAnim.end = true;

		} //

		/**
		 * when the player is in destroy mode and hiliting land, the game needs to lock
		 * the player's movement and also show the hilite box.
		 */
		public function lockPlayer():void {

			//var player:Entity = this.landGroup.getPlayer();

			//if ( this.motionControl.lockInput == false ) {

				CharUtils.lockControls( this.landGroup.getPlayer(), true );
				Cursor( this.landGroup.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.TARGET;

			//}

		} //
		
		public function unlockPlayer():void {

			CharUtils.lockControls( this.landGroup.getPlayer(), false, false );
			Cursor( this.landGroup.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.NAVIGATION_ARROW;

		} //

		private function onLevelUp( newLevel:int, unlocked:Vector.<ObjectIconPair> ):void {

			if ( this.masterNode ) {
				this.masterNode.strikeTarget.strikeTime = this.TILE_DESTROY_TIME*Math.exp( -newLevel/10 );
			}

		} //

		private function onLevelChanged( newLevel:int ):void {

			if ( this.masterNode ) {
				this.masterNode.strikeTarget.strikeTime = this.TILE_DESTROY_TIME*Math.exp( -newLevel/10 );
			}

		} //

		/**
		 * There should only ever be ONE node added.
		 */
		private function editNodeAdded( node:LandEditNode ):void {

			this.masterNode = node;

			var gameData:LandGameData = this.landGroup.gameData;
			gameData.progress.onLevelChanged.add( this.onLevelChanged );
			gameData.progress.onLevelUp.add( this.onLevelUp );

			this.editContext = this.masterNode.editContext;

			this.masterNode.strikeTarget.strikeTime = this.TILE_DESTROY_TIME*Math.exp( -gameData.progress.curLevel/10 );
			node.strikeTarget.strikeFunc = this.onLightningStrike;

			var inventory:LandInventory = gameData.inventory;

			this.popResource = inventory.getResource( "poptanium" );
			this.expResource = inventory.getResource( "experience" );

		} //

		/**
		 * creates a glitter effect for the hammer for edit mode.
		 */
		private function initHammerGlitter():void {
			
			var d:DisplayObjectRenderer = new DisplayObjectRenderer();
			d.x = d.y = 0;
			d.mouseEnabled = d.mouseChildren = false;
			this.landGroup.curScene.hitContainer.addChild( d );

			var skin:Skin = this.landGroup.getPlayer().get( Skin ) as Skin;
			var item:Entity = skin.getSkinPartEntity( "item" );

			this.glitterEffect = new GlitterEffect( d, item.get( Display ) as Display );
			this.glitterEffect.init();
			d.addEmitter( this.glitterEffect );

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.editNodes = systemManager.getNodeList( LandEditNode );
			this.editNodes.nodeAdded.add( this.editNodeAdded );
			//this.editNodes.nodeRemoved.add( this.editNodeRemoved );

			this.editNodeAdded( this.editNodes.head );

			//this.motionControl = this.landGroup.getPlayer().get( MotionControl );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.editNodes.nodeAdded.remove( this.editNodeAdded );
			//this.editNodes.nodeRemoved.remove( this.editNodeRemoved );

			this.popResource = this.expResource = null;

			this.landGroup = null;
			this.editContext = null;
			this.glitterEffect = null;
			this.scrollControl = null;

			this.editNodes = null;

		} //

	} // class

} // package