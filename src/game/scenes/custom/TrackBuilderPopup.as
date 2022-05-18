package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.motion.Draggable;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.scenes.custom.trackBuilderSystems.TrackBuilderSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.DraggableSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.utils.AdUtils;
	
	public class TrackBuilderPopup extends Popup
	{
		private var _startButton:Entity;
		private var _sponsorButton:Entity;
		private var _pieceButton1:Entity;
		private var _pieceButton2:Entity;
		private var _pieceButton3:Entity;
		private var _pieceButton4:Entity;
		private var _pieceButton5:Entity;
		private var _pieceButton6:Entity;
		
		private var _setupScreen:MovieClip;
		private var _runScreen:MovieClip;
		
		private var _dragSystem:System;
		private var _runSystem:System;
		
		private var _draggableEntities:Array;
		private var _draggableClips:Array;
		private var _draggableTile:Entity;
		private var _draggableTile1:Entity;
		private var _draggableTile2:Entity;
		private var _draggableTile3:Entity;
		private var _draggableTile4:Entity;
		private var _draggableTile5:Entity;
		private var _draggableTile6:Entity;
		private var _draggableComponent:Draggable;
		
		private var _originalTilePositions:Array;
		private var _originalRotations:Array;
		private var _lockedPieces:Array;
		
		private var _campaignId:String;
		private var _clickUrl:String;
		
		public function TrackBuilderPopup()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			// darken background
			super.darkenBackground = true;
			
			// assets will be found in campaign folder in custom/limited folder
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			
			_campaignId = super.data.campaignId;
			_clickUrl = super.data.clickUrl;
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		override public function loaded():void
		{		
			super.screen = MovieClip(super.getAsset( super.data.swfPath, true));
			_setupScreen = super.screen.content.setupScreen;
			_runScreen = super.screen.content.runScreen;
			_runScreen.visible = false;
			
			_startButton = setupButton(_setupScreen.mc_startButton, onStartClicked);
			
			_sponsorButton = setupButton(_setupScreen.mc_sponsorButton, onSponsorClicked);
			
			_setupScreen.mc_lockedPiece1.gotoAndStop(1);
			_setupScreen.mc_lockedPiece2.gotoAndStop(1);
			_setupScreen.mc_lockedPiece3.gotoAndStop(1);
			_setupScreen.mc_lockedPiece4.gotoAndStop(1);
			_setupScreen.mc_lockedPiece5.gotoAndStop(1);
			_setupScreen.mc_lockedPiece6.gotoAndStop(1);
			
			_lockedPieces = new Array(_setupScreen.mc_lockedPiece1, _setupScreen.mc_lockedPiece2, _setupScreen.mc_lockedPiece3, _setupScreen.mc_lockedPiece4, _setupScreen.mc_lockedPiece5, _setupScreen.mc_lockedPiece6);
			
			_dragSystem = this.addSystem( new DraggableSystem(), SystemPriorities.update );
			
			_draggableClips = new Array(_setupScreen.mc_draggablePiece1, _setupScreen.mc_draggablePiece2, _setupScreen.mc_draggablePiece3, _setupScreen.mc_draggablePiece4, _setupScreen.mc_draggablePiece5, _setupScreen.mc_draggablePiece6);
			
			_originalTilePositions = new Array();
			_originalTilePositions.push(new Array(_setupScreen.mc_draggablePiece1.x, _setupScreen.mc_draggablePiece1.y));
			_originalTilePositions.push(new Array(_setupScreen.mc_draggablePiece2.x, _setupScreen.mc_draggablePiece2.y));
			_originalTilePositions.push(new Array(_setupScreen.mc_draggablePiece3.x, _setupScreen.mc_draggablePiece3.y));
			_originalTilePositions.push(new Array(_setupScreen.mc_draggablePiece4.x, _setupScreen.mc_draggablePiece4.y));
			_originalTilePositions.push(new Array(_setupScreen.mc_draggablePiece5.x, _setupScreen.mc_draggablePiece5.y));
			_originalTilePositions.push(new Array(_setupScreen.mc_draggablePiece6.x, _setupScreen.mc_draggablePiece6.y));
			
			_originalRotations = new Array();
			_originalRotations.push(_setupScreen.mc_draggablePiece1.rotation);
			_originalRotations.push(_setupScreen.mc_draggablePiece2.rotation);
			_originalRotations.push(_setupScreen.mc_draggablePiece3.rotation);
			_originalRotations.push(_setupScreen.mc_draggablePiece4.rotation);
			_originalRotations.push(_setupScreen.mc_draggablePiece5.rotation);
			_originalRotations.push(_setupScreen.mc_draggablePiece6.rotation);
			
			_draggableTile1 = EntityUtils.createSpatialEntity(this, _setupScreen.mc_draggablePiece1);
			_draggableTile2 = EntityUtils.createSpatialEntity(this, _setupScreen.mc_draggablePiece2);
			_draggableTile3 = EntityUtils.createSpatialEntity(this, _setupScreen.mc_draggablePiece3);
			_draggableTile4 = EntityUtils.createSpatialEntity(this, _setupScreen.mc_draggablePiece4);
			_draggableTile5 = EntityUtils.createSpatialEntity(this, _setupScreen.mc_draggablePiece5);
			_draggableTile6 = EntityUtils.createSpatialEntity(this, _setupScreen.mc_draggablePiece6);
			
			_draggableEntities = new Array(_draggableTile1, _draggableTile2, _draggableTile3, _draggableTile4, _draggableTile5, _draggableTile6);
			
			InteractionCreator.addToEntity(_draggableTile1, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], _setupScreen.mc_draggablePiece1);
			InteractionCreator.addToEntity(_draggableTile2, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], _setupScreen.mc_draggablePiece2);
			InteractionCreator.addToEntity(_draggableTile3, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], _setupScreen.mc_draggablePiece3);
			InteractionCreator.addToEntity(_draggableTile4, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], _setupScreen.mc_draggablePiece4);
			InteractionCreator.addToEntity(_draggableTile5, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], _setupScreen.mc_draggablePiece5);
			InteractionCreator.addToEntity(_draggableTile6, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], _setupScreen.mc_draggablePiece6);
			
			_draggableComponent = new Draggable();
			_draggableComponent.drag.add(tileGrabbed);
			_draggableComponent.drop.add(tileDropped);
			_draggableTile1.add(_draggableComponent);
			
			_draggableComponent = new Draggable();
			_draggableComponent.drag.add(tileGrabbed);
			_draggableComponent.drop.add(tileDropped);
			_draggableTile2.add(_draggableComponent);
			
			_draggableComponent = new Draggable();
			_draggableComponent.drag.add(tileGrabbed);
			_draggableComponent.drop.add(tileDropped);
			_draggableTile3.add(_draggableComponent);
			
			_draggableComponent = new Draggable();
			_draggableComponent.drag.add(tileGrabbed);
			_draggableComponent.drop.add(tileDropped);
			_draggableTile4.add(_draggableComponent);
			
			_draggableComponent = new Draggable();
			_draggableComponent.drag.add(tileGrabbed);
			_draggableComponent.drop.add(tileDropped);
			_draggableTile5.add(_draggableComponent);
			
			_draggableComponent = new Draggable();
			_draggableComponent.drag.add(tileGrabbed);
			_draggableComponent.drop.add(tileDropped);
			_draggableTile6.add(_draggableComponent);
			
			_draggableTile1.add(new Id("1"));
			_draggableTile2.add(new Id("2"));
			_draggableTile3.add(new Id("3"));
			_draggableTile4.add(new Id("4"));
			_draggableTile5.add(new Id("5"));
			_draggableTile6.add(new Id("6"));
			
			ToolTipCreator.addUIRollover(_draggableTile1);
			ToolTipCreator.addUIRollover(_draggableTile2);
			ToolTipCreator.addUIRollover(_draggableTile3);
			ToolTipCreator.addUIRollover(_draggableTile4);
			ToolTipCreator.addUIRollover(_draggableTile5);
			ToolTipCreator.addUIRollover(_draggableTile6);
			
			for ( var i:int = 0; i < _draggableEntities.length; i ++ )
				_draggableEntities[i].get(Display).alpha = 0;
			
			super.loaded();
		}
		
		private function onPiece1Clicked(entity:Entity):void { pieceClicked(1); }
		private function onPiece2Clicked(entity:Entity):void { pieceClicked(2); }
		private function onPiece3Clicked(entity:Entity):void { pieceClicked(3); }
		private function onPiece4Clicked(entity:Entity):void { pieceClicked(4); }
		private function onPiece5Clicked(entity:Entity):void { pieceClicked(5); }
		private function onPiece6Clicked(entity:Entity):void { pieceClicked(6); }
		
		private function pieceClicked(pieceNum:int):void
		{
			_setupScreen.mc_draggablePiece.gotoAndStop(pieceNum);
			_setupScreen.mc_draggablePiece.x = _setupScreen.mouseX;
			_setupScreen.mc_draggablePiece.y = _setupScreen.mouseY;
		}
		
		private function tileGrabbed(entity:Entity):void
		{
			var tileNum:int = parseInt(entity.get(Id).id, 10);
			_draggableEntities[tileNum - 1].get(Spatial).rotation = 0;
			_draggableEntities[tileNum - 1].get(Display).alpha = 1;
		}
		
		private function tileDropped(entity:Entity):void
		{
			var tileNum:int = parseInt(entity.get(Id).id, 10);
			
			if ( _draggableClips[tileNum - 1].hitTestObject(_setupScreen.mc_lockedPieces) )
			{
				for ( var i:int = 1; i < _lockedPieces.length; i ++ )
				{
					if ( (_draggableClips[tileNum - 1].x + (0.5 * _draggableClips[tileNum - 1].width)) < _lockedPieces[i].x )
					{
						_lockedPieces[i - 1].gotoAndStop(tileNum);
						i = _lockedPieces.length;
					}
					else if ( i == _lockedPieces.length - 1 )
						_lockedPieces[i].gotoAndStop(tileNum);
				}
			}
			
			_draggableEntities[tileNum - 1].get(Display).alpha = 0;
			_draggableEntities[tileNum - 1].get(Spatial).x = _originalTilePositions[tileNum - 1][0];
			_draggableEntities[tileNum - 1].get(Spatial).y = _originalTilePositions[tileNum - 1][1];
			_draggableEntities[tileNum - 1].get(Spatial).rotation = _originalRotations[tileNum - 1];
		}
		
		private function onStartClicked(entity:Entity):void
		{
			this.removeSystem(_dragSystem);
			
			_runScreen.visible = true;
			_setupScreen.visible = false;
			
			var trackArray:Array = new Array();
			for ( var i:int = 0; i < _lockedPieces.length; i ++ )
				trackArray.push(_lockedPieces[i].currentFrame);
			
			_runSystem = this.addSystem(new TrackBuilderSystem(this, _runScreen, trackArray), SystemPriorities.update);
		}
		
		private function onSponsorClicked(entity:Entity):void
		{
			AdManager(super.shellApi.adManager).track(_campaignId, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, "Popup", "TrackBuilder");
			AdUtils.openSponsorURL(super.shellApi, _clickUrl, _campaignId, "Popup", "TrackBuilder");
		}
		
		public function endRun():void
		{
			this.removeSystem(_runSystem);
			super.remove();
		}
		
		private function setupButton(button:MovieClip, action:Function):Entity
		{
			if (button == null)
			{
				trace("null button");
				return null;
			}
			else
			{
				// force button to vanish (it flashes otherwise)
				button.alpha = 0;
				
				//create button entity
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(button.x, button.y));
				buttonEntity.add(new Display(button));
				buttonEntity.get(Display).alpha = 0;
				
				// add enity to group
				super.addEntity(buttonEntity);
				
				// add tooltip
				ToolTipCreator.addToEntity(buttonEntity);
				
				// add interaction
				var interaction:Interaction;
				interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], button);
				interaction.click.add(action);
				return buttonEntity;
			}
		}
	}
}