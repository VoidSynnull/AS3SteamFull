package game.scenes.myth.treeBottom.popups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.data.TimedEvent;
	import game.scenes.virusHunter.backRoom.components.PaperPiece;
	import game.scenes.virusHunter.backRoom.components.PaperPieces;
	import game.scenes.virusHunter.backRoom.systems.PaperPiecesSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Scramble extends Popup
	{
		public function Scramble( container:DisplayObjectContainer=null )
		{
			super(container);
		}
		
		override public function destroy():void
		{			
			for each(var interaction:Interaction in _interactions){
				interaction.removeAll(); // correct?
			}
			
			_interactions = null;
			_pieces = null;
			
			complete.removeAll();
			complete = null;
			
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/treeBottom/";
			super.init( container );
			super.autoOpen = false;
			
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "scramble.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "scramble.swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
			loadCloseButton();
			
			super.loaded();
			super.open();
			
			initPieces();
		}
		
		/**
		 * 
		 */
		private function initPieces():void
		{
			/**
			 * Jumble the pieces within an area randomly.
			 * Add an interaction to each of the pieces.
			 */
			
				piecesManager = new Entity()
					.add(new PaperPieces());
			
				super.addEntity( piecesManager );
			
			for( var number:int = 0; number < 5; number++ )
			{
				
				// blueprint piece
				var entity:Entity = new Entity().add( new Display( super.screen.content[ "p" + number ])).add( new PaperPiece( number, 1 ));
				
				// jumble pieces
				super.screen.content[ "p" + number ].x = Math.random() * 500 + 50;
				super.screen.content[ "p" + number ].y = Math.random() * 300 + 100;
				
				// create interaction for each piece
				var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT, InteractionCreator.OUT]);
				interaction.down.add( pieceDown );
				interaction.up.add( pieceUp );
				interaction.releaseOutside.add( pieceUp );
				_interactions.push( interaction );
				
				super.addEntity( entity );
				
				_pieces.push( entity );
				PaperPieces( piecesManager.get( PaperPieces )).bpPieces.push( entity );
				
				super.addSystem( new PaperPiecesSystem( super.screen.content ), SystemPriorities.autoAnim );
			}
		}
		
		private function pieceDown( $entity:Entity ):void
		{
			/**
			 * When piece is touched or "down" - set the PaperPiece.down = true
			 * The PaperPiecesSystem will scan each piece for a down == true and move it while it's down
			 * PaperPiecesSystem will also find any connected pieces and move them together.
			 * 
			 * 
			 * 
			 * TODO: Add an releaseOutside functionality
			 * 
			 *
			 */
			PaperPiece( $entity.get( PaperPiece )).down = true;
			PaperPiece( $entity.get( PaperPiece )).up = false;
			
			PaperPiece( $entity.get( PaperPiece )).offsetX = DisplayObjectContainer( super.screen.content ).mouseX -  Display( $entity.get( Display )).displayObject.x;
			PaperPiece( $entity.get( PaperPiece )).offsetY = DisplayObjectContainer( super.screen.content ).mouseY -  Display( $entity.get( Display )).displayObject.y;
			
			DisplayObjectContainer( super.screen.content ).setChildIndex( Display( $entity.get( Display )).displayObject, DisplayObjectContainer( super.screen.content ).numChildren - 1 );
		
		//	var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
			super.shellApi.triggerEvent( "moved_paper" );
			// release picked old up piece if not already - fixes a bug
			if( _pickedUpPiece )
			{
				if( _pickedUpPiece != $entity )
				{
					Interaction( _pickedUpPiece.get( Interaction )).up.dispatch( _pickedUpPiece );
				}
			}
			
			// update _pickedUpPiece to the new picked up piece
			_pickedUpPiece = $entity;
			
		}
		
		private function pieceUp( $entity:Entity ):void
		{
			/**
			 * When a piece is let go, stop moving it by setting "down" = false
			 * Then scan for neighboring compatible pieces within an area.
			 * If one is found, "join them" and snap this piece into place.
			 */
			var draggedPiece:PaperPiece = $entity.get( PaperPiece );
			draggedPiece.down = false;
			draggedPiece.up = true;
			
			var draggedClip:DisplayObject = Display( $entity.get( Display )).displayObject;
			
			var potentialMatches:Vector.<Entity>;
			
			switch( draggedPiece.type )
			{
				case 1:
					potentialMatches = nearbyMatches( $entity, _pieces );
					break;
			}
			
			if(potentialMatches.length > 0)
			{
				// join pieces
				for each( var pieceEntity:Entity in potentialMatches )
				{
					var matchPiece:PaperPiece = pieceEntity.get( PaperPiece );
					var matchClip:DisplayObject = Display( pieceEntity.get( Display )).displayObject;
					if(matchPiece.id < draggedPiece.id)
					{ // matchPiece is left
						draggedClip.x = matchClip.x + ( matchClip.width / 2 ) + ( draggedClip.width / 2 );
						draggedClip.y = matchClip.y;
						matchPiece.joinedRight = $entity;
						if ( draggedPiece.joinedLeft == null ) 
						{
							super.shellApi.triggerEvent( "connect_paper" );
						}
						draggedPiece.joinedLeft = pieceEntity;
					} 
					else 
					{ // right
						draggedClip.x = matchClip.x - ( matchClip.width / 2 ) - ( draggedClip.width / 2 );
						draggedClip.y = matchClip.y;
						matchPiece.joinedLeft = $entity;
						if ( draggedPiece.joinedRight == null ) 
						{
							super.shellApi.triggerEvent( "connect_paper" );
						}
						draggedPiece.joinedRight = pieceEntity;
					}
				}
			}
			
			// check if blue print is finished, if so, signal out that it is complete.
			var foundBP:Boolean = piecesComplete( _pieces );
			
			if( foundBP == true )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, finishedScramble ));
			}		
		}
		
		private function piecesComplete( $pieces:Vector.<Entity> ):Boolean{
			var complete:Boolean = true;
			
			for( var number:int = 0; number < $pieces.length - 1; number++ )
			{
				if( PaperPiece( $pieces[ number ].get( PaperPiece )).joinedRight == null )
				{
					complete = false;
				}
			}
			
			return complete;
		}
		
		private function finishedScramble():void{
			if ( !completedPuzzle ) 
			{
				//		super.shellApi.triggerEvent( "playPageCompleteSound" );
				completedPuzzle = true;
			}
			// Signal that the blueprint has been found (completed)
			// NOTE: Scene should have this listener setup: popup.bpFound.addOnce(...)
			complete.dispatch();
		}
		
		private function nearbyMatches( $paperPieceEntity:Entity, $pieces:Vector.<Entity> ):Vector.<Entity>
		{
			
			/**
			 * Find nearby pieces in orientation to left or right of the piece and check if they have both the correct type or +/-1 id (left or right)
			 * If found, (up to 2 can be found) - return a vector of those possible entities.
			 */
			
			var sourceClip:DisplayObject = Display( $paperPieceEntity.get( Display )).displayObject;
			var sourcePiece:PaperPiece = $paperPieceEntity.get( PaperPiece );
			
			var matches:Vector.<Entity> = new Vector.<Entity>;
			
			for each( var entity:Entity in $pieces ){
				var clip:DisplayObject = Display( entity.get( Display )).displayObject;
				var piece:PaperPiece = entity.get( PaperPiece );
				
				if( Math.abs( sourceClip.x - clip.x ) < (( sourceClip.width / 2 + clip.width / 2 ) + 10 ) && ( Math.abs( sourceClip.x - clip.x ) > sourceClip.width / 2 ))
				{
				//	trace( Math.abs( sourceClip.x - clip.x ));
					if( Math.abs( sourceClip.y - clip.y ) < 20 )
					{
						trace( Math.abs( sourceClip.y - clip.y ));
						// check if id's line up
						if( sourceClip.x < clip.x ){ // check left
							if( sourcePiece.id == piece.id - 1 )
							{
								matches.push( entity );
							}
						} 
						else if( sourcePiece.id == piece.id +1 )
						{ // check right
							matches.push( entity );
						}
					}
				}
			}
			return matches;
		}
		
		private var _pieces:Vector.<Entity> = new Vector.<Entity>;
		
		public var complete:Signal = new Signal();
		
		public var piecesManager:Entity;
		private var _interactions:Vector.<Interaction> = new Vector.<Interaction>; // store interactions for garbage collection on close
		private var completedPuzzle:Boolean = false;
		private var _pickedUpPiece:Entity;
	}
}