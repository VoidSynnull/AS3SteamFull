package game.scenes.time.mali2
{
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.creators.motion.DraggableCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.game.GameEvent;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.mali2.components.PuzzlePiece;
	import game.systems.SystemPriorities;
	import game.systems.motion.DraggableSystem;
	import game.systems.motion.SpatialToMouseSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	
	public class MaliDocs extends Popup
	{
		private var _connections:Array;
		private var _selectedPiece:PuzzlePiece;
		
		private var events:TimeEvents;
		private var piecesInited:Boolean;
		private var talkingHead:Entity;
		private var _victory:Boolean;
		
		// ranges for snapping to pieces
		private const XMax:Number = 100;
		private const XMin:Number = 50;
		private const YMax:Number = 60;
		private const YMin:Number = 30;
		
		public var complete:Signal = new Signal();
		
		public function MaliDocs( container:DisplayObjectContainer=null )
		{
			super( container );
		}
		
		override public function destroy():void
		{			
			// garbage collect interaction signals
			_connections = null;
			complete.removeAll();
			super.shellApi.eventTriggered.remove( this.handleEventTriggered );
			super.destroy();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{
			// setup the transitions 
			
			_connections = new Array();
			_victory = false;
			piecesInited = false
				
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
			super.transitionOut = super.transitionIn.duplicateSwitch();			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/time/mali2/docsPopup/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles([GameScene.NPCS_FILE_NAME,GameScene.DIALOG_FILE_NAME,"maliDocs.swf"], false, true, loaded);
		}	
		
		// all assets ready
		override public function loaded():void
		{			
			
			events = shellApi.islandEvents as TimeEvents;			
			
			super.screen = super.getAsset("maliDocs.swf", true) as MovieClip;
			
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640), false);
			
			this.screen.content.board.alpha = 0;
			//this.layout.centerUI( super.screen.content );
			//this.layout.centerUI( super.screen );
			
			//_contentEnt = EntityUtils.createSpatialEntity( this, super.screen.content );
			//_contentEnt.add( new Id( "content" ));
			
			//_contentDisplay = _contentEnt.get( Display );
			//_contentDisplay.alpha = 0;
			
			super.shellApi.eventTriggered.add( this.handleEventTriggered );
			super.addSystem( new DraggableSystem(), SystemPriorities.move );
			
			super.loadCloseButton();
			super.loaded();
			
			setupTalkingHead();
		}
		
		private function handleEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch( event )
			{
				case events.MALIDOCS_COMPLETE:
					playEndMessage( talkingHead );
					break;
				
				case events.MALIDOCS_START: 
					if( !piecesInited )
					{
						initPuzzlePieces();
					}
					break;
				
				case events.MALIDOCS_EXIT:
					complete.dispatch();
					break;
			}
		}	
		
		public function setupTalkingHead():void
		{
			//load head and start npc talking, opens puzzle after he's done	
			var characterGroup:CharacterGroup = new CharacterGroup();
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();

			characterGroup.setupGroup( this, super.screen, super.getData( GameScene.NPCS_FILE_NAME ), allCharactersLoaded );				
			characterDialogGroup.setupGroup( this, super.getData( GameScene.DIALOG_FILE_NAME ), super.screen );
		}
		
		protected function allCharactersLoaded():void
		{
			talkingHead = super.getEntityById( "merc" );
			Dialog(talkingHead.get(Dialog)).container = this.screen;
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,Command.create(playStartMessage,talkingHead)));
			//playStartMessage( talkingHead );
		}
		
		private function initPuzzlePieces():void
		{
			/**
			 * Jumble the pieces within an area randomly.
			 * Add an interaction to each of the pieces.
			 */
			var p:int = 0;
			var startX:Number = 0;
			var startY:Number = 0;
			var piece:PuzzlePiece;
			var clip:MovieClip;
			var creator:DraggableCreator = new DraggableCreator();
			var pos:Point;
			var entity:Entity;
			
			this.addSystem(new SpatialToMouseSystem());
			
			var draggable:Draggable;
			
			// rows and columns
			_connections = new Array( new Array());
			for(var r:int = 0; r < 6; r++)
			{
				_connections[ r ] = new Array( 3 );
				for(var c:int = 0; c < 3; c++)
				{
					p++;					
					clip = super.screen.content.board[ "pc" + p ];
					startX = Utils.randInRange(-250, 250);// + this.screen.content.board.x;
					startY = Utils.randInRange(-150, 150);// +this.screen.content.board.y;
					
					entity = EntityUtils.createSpatialEntity(this, clip);
					InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
					entity.add(new Draggable());
					EntityUtils.position( entity, startX, startY );
					
					ToolTipCreator.addToEntity(entity);
					
					piece = new PuzzlePiece( c, r );
					entity.add( piece );
					
					entity.add( new Id( "piece" + p ));
					entity.add( new Edge( -50, -25, 50, 25 ));  //( -.5 * clip.width, -.5 * clip.height, .5 * clip.width, .5 * clip.height ));
					
					draggable = entity.get( Draggable );	
					draggable.drag.add( pieceDown );
					draggable.drop.add( pieceUp );
					
					_connections[ r ][ c ] = entity;
				}
			}
			// enter backBoard
		
			Tween(this.getGroupEntityComponent(Tween)).to( this.screen.content.board, 1, { alpha : 1 });
			piecesInited = true;
			
		}
		
		private function pieceDown( entity:Entity, extra:Boolean = false ):void
		{
			var piece:PuzzlePiece = entity.get( PuzzlePiece );
			
			snapPieces(entity,piece, true);
			
			//90, 45
			if( !extra )
			{
				_selectedPiece = piece;
				shellApi.triggerEvent( "pickup_piece_sound" );
			}
			
			/**
			 * When piece is touched or "down" - set the draggable.dragging = true
			 * Will search for connected entites and set their draggable.dragging = true
			 */
			if( _victory )
			{
				var draggable:Draggable = entity.get( Draggable );
				draggable.onDrop();
				return;
			}
			
			
		}
		
		private function invalidateFollower(follower:Entity, draggedSpatial:Spatial, offsetX:Number, offsetY:Number, dragging:Boolean):void
		{
			var spatial:Spatial = follower.get(Spatial);
			
			//Checking if not dragging and pieces are already where they need to be. Removing this causing endless looping.
			if(!dragging && (draggedSpatial.x + offsetX) - spatial.x < 1 && (draggedSpatial.y + offsetY) - spatial.y < 1) return;
			
			spatial.x = draggedSpatial.x + offsetX;
			spatial.y = draggedSpatial.y + offsetY;
			
			var draggable:Draggable = follower.get( Draggable );
			if(dragging)
			{
				if(!draggable._active)
				{
					var display:DisplayObject = follower.get(Display).displayObject;
					draggable.offsetX = spatial.x - display.parent.mouseX;
					draggable.offsetY = spatial.y - display.parent.mouseY;
					draggable.onDrag();
					
					pieceDown( follower, true );
				}
			}
			else
			{
				draggable.onDrop();
				pieceUp(follower);
			}
		}
		
		private function pieceUp( entity:Entity ):void
		{
			/**
			 * When a piece is let go, turns off all draggables.
			 * Tallies how many were active and determines victory from that count.
			 */
			var potentialMatches:Vector.<Entity> = nearbyMatches( entity );
			var piece:PuzzlePiece = entity.get(PuzzlePiece);		
			
			var checkEnt:Entity;
			var checkPiece:PuzzlePiece;
			
			var victoryCount:int = 0;
			var playThatSound:Boolean = false;

			if( potentialMatches.length > 0 )
			{
				// join pieces right & left
				for each( checkEnt in potentialMatches )
				{
					checkPiece = checkEnt.get(PuzzlePiece);
					
					if(checkPiece.columnId < piece.columnId)
					{ 
						if( !(checkPiece.joinedRight || piece.joinedLeft ))
						{
							if( !(checkPiece.connected && piece.connected ))
							{
								playThatSound = true;
							}
							
							checkPiece.connected = true;
							piece.connected = true;
							checkPiece.joinedRight = true;
							piece.joinedLeft = true;
						}
					} 
					
					else if( checkPiece.columnId > piece.columnId )
					{
						if( !(checkPiece.joinedLeft || piece.joinedRight ))
						{
							if( !(checkPiece.connected && piece.connected ))
							{
								playThatSound = true;
							}
							
							checkPiece.connected = true;
							piece.connected = true;
							checkPiece.joinedLeft = true;
							piece.joinedRight = true;
						}
					}
					
					else if( checkPiece.rowId < piece.rowId )
					{
						if( !(checkPiece.joinedBottom || piece.joinedTop ))
						{
							if( !(checkPiece.connected && piece.connected ))
							{
								playThatSound = true;
							}
							
							checkPiece.connected = true;
							piece.connected = true;
							checkPiece.joinedBottom = true;
							piece.joinedTop = true;
						}
					} 
					
					else if( checkPiece.rowId > piece.rowId )
					{ 
						if( !(checkPiece.joinedTop || piece.joinedBottom ))
						{
							if( !(checkPiece.connected && piece.connected ))
							{
								playThatSound = true;
							}
							
							checkPiece.connected = true;
							piece.connected = true;
							checkPiece.joinedTop = true;
							piece.joinedBottom = true;
						}
					}
				}
			}
			
			snapPieces(entity, piece, false);
			
			if( playThatSound )
			{
				shellApi.triggerEvent( "piece_connected_sound" );
			}
			
			for( var number:int = 1; number < 19; number ++ )
			{	
				entity = getEntityById( "piece" + number );
				var puzzlePiece:PuzzlePiece = entity.get( PuzzlePiece );
				
				if( puzzlePiece.connected )
				{
					//draggable.onDrop();
					victoryCount ++;
				}
				
				var draggable:Draggable = entity.get(Draggable);
				if(draggable._active) draggable.onDrop();
			}
			
			if( victoryCount == 18 )
			{
				super.shellApi.triggerEvent( events.MALIDOCS_COMPLETE, true );	
				_victory = true;
			}
		}
		
		private function snapPieces(entity:Entity, piece:PuzzlePiece, dragging:Boolean):void
		{
			var draggedSpatial:Spatial = entity.get(Spatial);
			
			var follower:Entity;
			
			if( piece.joinedBottom )
			{
				follower = _connections[ piece.rowId + 1 ][ piece.columnId ];
				this.invalidateFollower(follower, draggedSpatial, 0, 45, dragging);
			}
			if( piece.joinedLeft )
			{
				follower = _connections[ piece.rowId ][ piece.columnId - 1 ];
				this.invalidateFollower(follower, draggedSpatial, -90, 0, dragging);
			}
			if( piece.joinedRight )
			{
				follower = _connections[ piece.rowId ][ piece.columnId + 1 ];
				this.invalidateFollower(follower, draggedSpatial, 90, 0, dragging);
			}
			if( piece.joinedTop )
			{
				follower = _connections[ piece.rowId - 1 ][ piece.columnId ];
				this.invalidateFollower(follower, draggedSpatial, 0, -45, dragging);
			}
		}
		
		private function nearbyMatches( entity:Entity ):Vector.<Entity>
		{
			
			/**
			 * Find nearby pieces in orientation to left, right, above or below of the piece and check if they have both the correct id's
			 * If found, (up to 4 can be found) - return a vector of those possible entities.
			 */			
			var spatial:Spatial = entity.get( Spatial );
			var piece:PuzzlePiece = entity.get( PuzzlePiece );			
			var matches:Vector.<Entity> = new Vector.<Entity>;		
			
			var checkEnt:Entity;
			var checkSpatial:Spatial;
			var checkPiece:PuzzlePiece;
			for( var number:int = 1; number < 19; number ++ )
			{	
				checkEnt = getEntityById( "piece" + number );
				checkSpatial = checkEnt.get( Spatial );
				checkPiece = checkEnt.get(PuzzlePiece);
				
				if( (checkSpatial.x - spatial.x < XMax 
					&& checkSpatial.x - spatial.x > XMin 
					&& Math.abs( checkSpatial.y - spatial.y ) < YMin
					&& piece.rowId == checkPiece.rowId 
					&& piece.columnId == checkPiece.columnId-1 )

					|| ( spatial.x - checkSpatial.x < XMax 
					&&  Math.abs( checkSpatial.y - spatial.y ) < YMin 
					&& spatial.x - checkSpatial.x > XMin 
					&& piece.rowId == checkPiece.rowId 
					&& piece.columnId == checkPiece.columnId+1 )

					|| ( checkSpatial.y - spatial.y < YMax 
					&& checkSpatial.y - spatial.y > YMin 
					&& Math.abs( checkSpatial.x - spatial.x ) < XMin 
					&& piece.columnId == checkPiece.columnId 
					&& piece.rowId == checkPiece.rowId-1 ) 

					|| ( spatial.y - checkSpatial.y < YMax 
					&& spatial.y - checkSpatial.y > YMin 
					&& Math.abs( checkSpatial.x - spatial.x ) < XMin 
					&& piece.columnId == checkPiece.columnId 
					&& piece.rowId == checkPiece.rowId+1 ))
					{	
						matches.push( checkEnt );
					}
			}
			return matches;
		}
		
		private function playStartMessage( char:Entity ):void
		{
			// talk only on first playthrough
			if(!shellApi.checkEvent( GameEvent.GOT_ITEM + events.DECLARATION ))
			{
				var dialog:Dialog = Dialog( char.get( Dialog ));
				dialog.sayById( "docTalk1" );
			}
			else
			{
				shellApi.triggerEvent( events.MALIDOCS_START );
			}
		}
		
		private function playEndMessage( char:Entity ):void
		{
			var dialog:Dialog = Dialog( char.get( Dialog ));
			dialog.sayById( "puzzleComplete" );
		}
	}
}