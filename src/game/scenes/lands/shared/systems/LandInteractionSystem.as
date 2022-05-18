package game.scenes.lands.shared.systems {
	
	/**
	 * Having a new entity with its own interactions and sceneInteractions and rollovers for every interactive
	 * tile in Lands would probably be a bad idea -- there could be hundreds of interactable tiles.
	 * 
	 * Instead the LandInteractionSystem makes a single rollover clip which is moved based on which landTile the user's mouse is rolled over.
	 * 
	 * Clicks for the last focused tile are remembered and the land interaction triggers when the player arrives.
	 * 
	 * Like many Land systems, there should only ever be one node in the node List - since it represents the land game entity.
	 **/
	
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.components.FocusTileComponent;
	import game.scenes.lands.shared.components.LandMeteor;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.components.TileInteractor;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.nodes.LandInteractionNode;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class LandInteractionSystem extends System {

		private var nodeList:NodeList;
		
		/**
		 * maps tile types (not ids) to their TileTypeSpecial object, for a quick check of whether
		 * a given tile is interactive.
		 */
		private var tileSpecials:Dictionary;
		
		/**
		 * the clip used to display land tool tips.
		 */
		private var rollOverClip:Sprite;
		
		/**
		 * Used to track whether the land focus has changed. If it hasn't changed, there's no reason to
		 * check for toolTip changes.
		 */
		private var lastFocusTile:LandTile;

		/**
		 * last tile actually clicked on by the user.
		 */
		//private var clickTarget:TileSelector;
		private var playerInteractor:TileInteractor;

		/**
		 * used to convert destination tile coordinates to x,y destination locations.
		 */
		private var tileHits:TileBitmapHits;

		private var landGroup:LandGroup;

		public function LandInteractionSystem( mainGroup:LandGroup ) {

			super();

			this.landGroup = mainGroup;

			var data:LandGameData = mainGroup.gameData;
			this.tileSpecials = data.tileSpecials;
			this.tileHits = data.tileHits;

			// saves the last tile clicked so the interaction can occur when the player reaches it.
			var clickTarget:TileSelector = new TileSelector();
			this.playerInteractor = new TileInteractor( clickTarget );
			mainGroup.getPlayer().add( this.playerInteractor, TileInteractor );

		} //

		override public function update( time:Number ):void {

			var node:LandInteractionNode = this.nodeList.head;
			if ( node.entity.sleeping ) {
				return;
			}

			// focused tile hasn't changed, or focus is background.
			if ( node.tileFocus.tile == null || node.editContext.curLayer.name != "foreground" ) {
				this.rollOverClip.visible = false;
				return;
			} else if ( node.tileFocus.tile == this.lastFocusTile ) {
				return;
			}

			this.lastFocusTile = node.tileFocus.tile;
			var special:TileTypeSpecial = this.tileSpecials[ node.tileFocus.type ];
			// check if an interaction exists for the focused tileType.
			if ( special == null || special.clickable == false ) {

				// the current focus tileType has no interaction and so there should be no rollover.
				this.rollOverClip.visible = false;
				return;

			} //

			// NOTE: for now, only clip tile types will be interactible.
			this.showRollOver( node.tileFocus.type as ClipTileType, node.tileFocus.tile, node.tileFocus.tileMap.tileSize );

		} // update()

		private function showRollOver( clipType:ClipTileType, focusTile:LandTile, tileSize:Number ):void {
			
			if ( clipType == null ) {
				return;
			}
			
			this.rollOverClip.width = clipType.clip.loaderInfo.width;
			this.rollOverClip.height = clipType.clip.loaderInfo.height;

			if ( focusTile.tileDataX >= 0 ) {
				this.rollOverClip.x = ( focusTile.col - focusTile.tileDataX )*tileSize + this.landGroup.gameData.mapOffsetX;
			} else {
				this.rollOverClip.x = ( focusTile.col - focusTile.tileDataX )*tileSize - this.rollOverClip.width + this.landGroup.gameData.mapOffsetX;
			}
			this.rollOverClip.y = ( focusTile.row - focusTile.tileDataY )*tileSize;
			this.rollOverClip.visible = true;
			
		} //

		private function onUIModeChanged( newMode:uint ):void {
			
			if ( ( newMode & (LandEditMode.PLAY + LandEditMode.MINING ) ) == 0 ) {

				this.lastFocusTile = null;
				this.rollOverClip.visible = false;
				this.rollOverClip.mouseEnabled = false;
			} else {
				this.rollOverClip.mouseEnabled = true;
			}
			
		} //

		private function clickLandTarget( e:MouseEvent ):void {

			var focus:FocusTileComponent = ( this.nodeList.head as LandInteractionNode ).tileFocus;			

			var clickTarget:TileSelector = this.playerInteractor.target;
			clickTarget.tile = focus.tile;
			clickTarget.tileMap = focus.tileMap;
			clickTarget.tileType = focus.type;

			var player:Entity = this.landGroup.getPlayer();
			var sp:Spatial = player.get( Spatial ) as Spatial;

			// distance from player to center of target.
			var dx:Number = sp.x - ( this.rollOverClip.x + this.rollOverClip.width/2 );
			var dest:Destination;

			if ( Math.abs(dx) < this.rollOverClip.width/2 ) {
				
				var edge:Edge = player.get( Edge );
				var playerY:Number = sp.y + edge.rectangle.bottom;
				
				if ( ((playerY + 8) > this.rollOverClip.y) && (playerY < (this.rollOverClip.y + this.rollOverClip.height) ) ) {
					dest = CharUtils.followPath( player, new <Point>[new Point( sp.x, playerY )], null, false );
				} else {
					dest = CharUtils.followPath( player, new <Point>[new Point( sp.x, this.rollOverClip.y + this.rollOverClip.height )], null, false );
				}
				
			} else if ( dx > 0 ) {

				dest = CharUtils.followPath( player, new <Point>[new Point( this.rollOverClip.x + this.rollOverClip.width + 8, this.rollOverClip.y+this.rollOverClip.height )], null, false );

			} else {

				dest = CharUtils.followPath( player, new <Point>[new Point( this.rollOverClip.x - 8, this.rollOverClip.y+this.rollOverClip.height )], null, false );
			} //

			dest.onFinalReached.addOnce( this.targetReached );

		} //

		/**
		 * make an entity attempt to interact with a given land tile.
		 * returns the entity's destination so the caller can track when they've reached the tile.
		 * might need to look into what happens on dest failure.
		 */
		public function interactTile( entity:Entity, selector:TileSelector ):TileInteractor {

			// target will be used to retrieve the tile being targeted when the entity arrives.
			var interactor:TileInteractor = entity.get( TileInteractor );
			if ( interactor == null ) {
				interactor = new TileInteractor( selector );
				entity.add( interactor, TileInteractor );
			} else {
				interactor.target = selector;
			}

			var sp:Spatial = entity.get( Spatial ) as Spatial;
			var destPoint:Point = this.tileHits.getTileCenter( selector.tile );

			// distance from player to center of target.
			var dx:Number = sp.x - destPoint.x;
			var dest:Destination;
			
			if ( dx > 0 ) {

				dest = CharUtils.followPath( entity, new <Point>[new Point( destPoint.x, destPoint.y )], null, false );

			} else {

				dest = CharUtils.followPath( entity, new <Point>[new Point( destPoint.x, destPoint.y )], null, false );

			} //

			//dest.onInterrupted.add( this.targetInterrupted );
			dest.onFinalReached.addOnce( this.targetReached );

			return interactor;

		} //

		/*private function targetInterrupted( e:Entity ):void {

			trace( "TARGET INTERRUPTED" );
			trace( "TARGET INTERRUPTED" );
			trace( "TARGET INTERRUPTED" );
			trace( "TARGET INTERRUPTED" );
			trace( "TARGET INTERRUPTED" );
			trace( "TARGET INTERRUPTED" );

		} //*/

		private function playSpecialSound(snd:String):void {
			if(snd != ""){
				AudioUtils.play( this.group, SoundManager.EFFECTS_PATH + snd, 1, false, SoundModifier.EFFECTS );
			}
		} //
		
		/**
		 * player arrived at land target.
		 */
		private function targetReached( actor:Entity ):void {

			var interactor:TileInteractor = actor.get( TileInteractor ) as TileInteractor;
			if ( interactor == null ) {
				return;
			}

			var targetTile:TileSelector = interactor.target;
			if ( targetTile == null ) {
				return;
			}

			var isPlayer:Boolean = false;
			if ( actor == this.landGroup.getPlayer() ) {
				isPlayer = true;

			} //

			var special:TileTypeSpecial = this.tileSpecials[ targetTile.tileType ];
			interactor.onInteracted.dispatch( actor, special );

			if ( special == null ) {
				// mistake. no interaction here after all. the tileType might have changed since the click, or it might be an unknown error.
				return;
			}

			var targetX:int, targetY:int;
			var type:String = special.specialType;

			switch ( type ) {

				case "swap":

					// if this is the currently selected tile, try to de-select it now.
					if ( isPlayer ) {

						if ( targetTile.tile == this.lastFocusTile ) {
							this.lastFocusTile = null;
							this.rollOverClip.visible = false;
						} //
	
						// special ability is a poptanium bonus or a refund of poptanium used to place the tile.
						if ( special.bonus > 0 || special.refund ) {
							this.collectPoptanium( special, targetTile );
						} //

					}

					this.playSpecialSound(special.sound);

					( targetTile.tileType as ClipTileType ).swapClipTile(
						this.landGroup.gameData.fgLayer, targetTile, special.swapTile, special.offsetX, special.offsetY );

					this.landGroup.gameData.sceneMustSave = true;

					break;

				case "food":

					this.doEatFood( actor, special, targetTile );

					break;

				case "race_start":
					
					this.doRaceStart( special );
					break;
				
				case "race_finish":
					
					this.doRaceFinish( special );
					break;
				
				case "cannon":

					this.doFireCannon( actor, special, targetTile );
					break;

			} // switch

			// tracking
			if ( isPlayer ) {
				this.landGroup.shellApi.track( "Interacted", targetTile.tileType.name, LandGroup.CAMPAIGN );
			}

		} // targetReached()
		
		private function resetCannonballPan():void {
			SceneUtil.addTimedEvent(this.group, new TimedEvent(1, 1, resetCannonballPan2, true));
		}
		
		private function resetCannonballPan2():void {
			this.group.shellApi.camera.jumpToTarget = false;
			this.group.shellApi.camera.target = this.group.shellApi.player.get(Spatial);
		}

		private function collectPoptanium( special:TileTypeSpecial, targetTile:TileSelector ):void {

			var amt:int;
			if ( special.refund ) {
				amt = ( targetTile.tileType as ClipTileType ).cost;
				if ( this.landGroup.worldMgr.publicMode ) {
					amt = Math.ceil( amt/10 );
				}
			} else {
				amt = 0.5*special.bonus*( 1 + Math.random() );
			}
			
			var targetX:Number = targetTile.tile.col*targetTile.tileMap.tileSize;
			var targetY:Number = targetTile.tile.row*targetTile.tileMap.tileSize;
			
			this.landGroup.collectPoptanium( targetX, targetY, amt );
			this.landGroup.gameData.sceneMustSave = true;		// make sure the scene treasure won't restore when you come back.

		} //

		private function doEatFood( entity:Entity, special:TileTypeSpecial, targetTile:TileSelector ):void {

			var life:Life = entity.get( Life ) as Life;
			if ( life != null ) {
				life.heal( special.bonus );
			}

			// If the player's current selection just got destroyed.
			if ( targetTile.tile == this.lastFocusTile ) {
				this.lastFocusTile = null;
				this.rollOverClip.visible = false;
			} //

			var targetX:int = targetTile.tile.col*targetTile.tileMap.tileSize;
			var targetY:int = targetTile.tile.row*targetTile.tileMap.tileSize;
			this.landGroup.displayFadeText( targetX, targetY, "Yum!", 0x00E600, SoundManager.EFFECTS_PATH + "chewing_2a.mp3" );
			
			( targetTile.tileType as ClipTileType ).swapClipTile(
				this.landGroup.gameData.fgLayer, targetTile, 0, special.offsetX, special.offsetY );
			
			this.landGroup.gameData.sceneMustSave = true;

		} //

		private function doRaceStart( special:TileTypeSpecial ):void {

			//trace("START RACE");
			var race:RaceSystem = this.group.getSystem( RaceSystem ) as RaceSystem;
			if ( race == null ) {
				race = new RaceSystem( );
				this.group.addSystem( race, SystemPriorities.update );
			} else {
				race.currentTime = 0;
			}
			playSpecialSound(special.sound);

		} //

		private function doRaceFinish( special:TileTypeSpecial ):void {

			//trace("FINISH RACE");
			var race1:RaceSystem = this.group.getSystem( RaceSystem ) as RaceSystem;
			if ( race1 != null ) {
				race1.finishRace();
				
				playSpecialSound(special.sound);
			}

		} //

		private function doFireCannon( user:Entity, special:TileTypeSpecial, cannonTile:TileSelector ):void {

			this.group.shellApi.loadFile( ( this.group as LandGroup ).sharedAssetURL + "cannonball.swf", this.onCannonLoaded,
				user, cannonTile );
			playSpecialSound( special.sound );

		} //

		/**
		 * player stopped/was interrupted before reaching the current target.
		 * clear anything about the target.
		 */
		/*private function targetInterrupted():void {
		} //*/
		
		private function onNodeAdded( node:LandInteractionNode ):void {
			
			if ( this.rollOverClip == null ) {
				
				this.createRollOverClip();
				
				var uiGroup:LandUIGroup = this.landGroup.getUIGroup();
				
				uiGroup.sharedTip.addClipTip( this.rollOverClip );
				uiGroup.inputManager.addEventListener( this.rollOverClip, MouseEvent.CLICK, this.clickLandTarget );

			}

		} //

		private function onNodeRemoved( node:LandInteractionNode ):void {

			this.rollOverClip.visible = false;

		} //
		
		override public function addToEngine( systemManager:Engine ):void {
			
			this.nodeList = systemManager.getNodeList( LandInteractionNode );
			this.nodeList.nodeAdded.add( this.onNodeAdded );
			this.nodeList.nodeRemoved.add( this.onNodeRemoved );
			
			if ( this.nodeList.head ) {
				this.onNodeAdded( this.nodeList.head );
			}

			this.landGroup.getUIGroup().onUIModeChanged.add( this.onUIModeChanged );

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			systemManager.releaseNodeList( LandInteractionNode );
			
			if ( this.rollOverClip ) {
				
				if ( this.rollOverClip.parent ) {
					this.rollOverClip.parent.removeChild( this.rollOverClip );
				}
				this.rollOverClip = null;
				
			} //

			this.landGroup.getUIGroup().onUIModeChanged.remove( this.onUIModeChanged );

		} //
		
		private function createRollOverClip():void {

			this.rollOverClip = new Sprite();
			this.rollOverClip.mouseChildren = false;
			this.rollOverClip.visible = false;

			var s:Shape = new Shape();
			this.rollOverClip.addChild( s );
			// alpha can be adjusted to reveal hilite for debugging.
			// object can't be invisible because it needs to take clicks.
			s.alpha = 0;

			var g:Graphics = s.graphics;
			g.beginFill( 0, 1.0 );
			g.drawRect( 0, 0, 64, 64 );
			g.endFill();

			this.landGroup.curScene.hitContainer.addChild( this.rollOverClip );
			//this.background.addChild( this.rollOverClip );
	
		} //
		
		/**
		 * get the source tile where a tile with a clipTileType starts.
		 */
		public function getSourceTile( landTile:LandTile, tileMap:TileMap ):LandTile {

			var srcCol:int = landTile.col + landTile.tileDataX;
			if ( srcCol < 0 || srcCol > tileMap.cols ) {
				return null;
			}

			var srcRow:int = landTile.row + landTile.tileDataY;
			if ( srcRow < 0 || srcRow >= tileMap.rows ) {
				return null;
			}

			return tileMap.getTile( srcRow, srcCol );

		} //

		/**
		 * CANNONBALL LOADED. This doesn't really belong here. Need a separate cannon system since it's not very general.
		 */
		private function onCannonLoaded( cannonball:MovieClip, shooter:Entity, cannonTile:TileSelector ):void {
			
			cannonball.mouseChildren = cannonball.mouseEnabled = false;
			
			// this motion component is 'heavy' for such a simple component. might not even use it.
			var motion:Motion = new Motion();
			
			var startX:Number;
			var startY:Number;

			if ( cannonTile.tile.tileDataX >= 0 ){
				motion.velocity.x = 800;
				startX = this.rollOverClip.x + this.rollOverClip.width/2 + 100;
				startY = this.rollOverClip.y + this.rollOverClip.height/2 - 30;
			} else {
				motion.velocity.x = -800;
				startX = this.rollOverClip.x + this.rollOverClip.width/2 - 100;
				startY = this.rollOverClip.y + this.rollOverClip.height/2 - 30;
			}
			
			motion.velocity.y = -100;
			motion.acceleration.y = 200;
			
			var ball:Entity = new Entity()
				.add( new Spatial( startX, startY ), Spatial )
				.add( new LandMeteor(), LandMeteor )
				.add( new Display( cannonball, ( this.group as LandGroup ).curScene.hitContainer ), Display )
				.add( motion, Motion );
			
			this.systemManager.addEntity( ball );
			
			if ( this.systemManager.getSystem( LandMeteorSystem ) == null ) {
				
				// no meteor system currently active.
				this.group.addSystem( new LandMeteorSystem(), SystemPriorities.update );
				
			}

			if ( shooter == this.landGroup.getPlayer() ) {
				// player fired the cannon. follow the cannonball with the camera.
				this.group.shellApi.camera.jumpToTarget = true;
				this.group.shellApi.camera.target = ball.get(Spatial);		
				( ball.get(LandMeteor) as LandMeteor ).onRemoved.addOnce( this.resetCannonballPan );
			}

		} //

	} // End class
	
} // End package