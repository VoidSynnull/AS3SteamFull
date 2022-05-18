package game.scenes.virusHunter.backRoom
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.data.ui.TransitionData;
	import game.scenes.virusHunter.backRoom.components.PaperPiece;
	import game.scenes.virusHunter.backRoom.components.PaperPieces;
	import game.scenes.virusHunter.backRoom.systems.PaperPiecesSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.DisplayPositionUtils;
	import game.util.DisplayUtils;
	
	import org.osflash.signals.Signal;
	
	public class BlueprintPopup extends Popup
	{
		public function BlueprintPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// garbage collect interaction signals
			for each(var interaction:Interaction in _interactions){
				interaction.removeAll(); // correct?
			}
			
			// reset all piece components
			resetPieces();
			
			_interactions = null;
			
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
			
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/virusHunter/backRoom/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("blueprintPopup.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("blueprintPopup.swf", true) as MovieClip;
			
			DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 986, 733.45);
			this.fitToDimensions(this.screen.background, true);
			
			//After resizing the screen, put these off-screen so they're not viewable. Not even sure if they're needed.
			this.screen.content.bpC.x = 2000;
			this.screen.content.pdC.x = 2000;
			this.screen.content.psC.x = 2000;
			
			// this loads the standard close button
			super.loadCloseButton();

			super.loaded();
			
			initPieces();
		}
		
		private function initPieces():void{
			
			/**
			 * Jumble the pieces within an area randomly.
			 * Add an interaction to each of the pieces.
			 */
			
			piecesManager = new Entity()
				.add(new PaperPieces());
			
			super.addEntity(piecesManager);
			
			for(var c:int = 1; c <= 9; c++){
				
				// blueprint piece
				var bpEntity:Entity = new Entity()
					.add(new Display(super.screen.content["bp"+c]))
					.add(new PaperPiece(c,1));
				
				// pizza delivery piece
				var pdEntity:Entity = new Entity()
					.add(new Display(super.screen.content["pd"+c]))
					.add(new PaperPiece(c,2));
				
				// pizza script piece
				var psEntity:Entity = new Entity()
					.add(new Display(super.screen.content["ps"+c]))
					.add(new PaperPiece(c,3));
				
				// jumble pieces
				super.screen.content["bp"+c].x = Math.random()*800 + 80;
				super.screen.content["bp"+c].y = Math.random()*150 + 340;
				
				super.screen.content["pd"+c].x = Math.random()*800 + 80;
				super.screen.content["pd"+c].y = Math.random()*150 + 340;
				
				super.screen.content["ps"+c].x = Math.random()*800 + 80;
				super.screen.content["ps"+c].y = Math.random()*150 + 340;
				
				// create interaction for each piece
				var bpInt:Interaction = InteractionCreator.addToEntity(bpEntity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT, InteractionCreator.OUT]);
				bpInt.down.add(pieceDown);
				bpInt.up.add(pieceUp);
				bpInt.releaseOutside.add(pieceUp);
				_interactions.push(bpInt);
				
				var pdInt:Interaction = InteractionCreator.addToEntity(pdEntity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT, InteractionCreator.OUT]);
				pdInt.down.add(pieceDown);
				pdInt.up.add(pieceUp);
				pdInt.releaseOutside.add(pieceUp);
				_interactions.push(pdInt);
				
				var psInt:Interaction = InteractionCreator.addToEntity(psEntity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT, InteractionCreator.OUT]);
				psInt.down.add(pieceDown);
				psInt.up.add(pieceUp);
				psInt.releaseOutside.add(pieceUp);
				_interactions.push(psInt);
				
				super.addEntity(bpEntity);
				super.addEntity(pdEntity);
				super.addEntity(psEntity);

				PaperPieces(piecesManager.get(PaperPieces)).bpPieces.push(bpEntity);
				PaperPieces(piecesManager.get(PaperPieces)).pdPieces.push(pdEntity);
				PaperPieces(piecesManager.get(PaperPieces)).psPieces.push(psEntity);
				
				super.addSystem(new PaperPiecesSystem(super.screen.content), SystemPriorities.autoAnim);
			}
		}
		
		private function pieceDown($entity:Entity):void{
			
			super.shellApi.triggerEvent("playPaperSound");
			
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
			PaperPiece($entity.get(PaperPiece)).down = true;
			PaperPiece($entity.get(PaperPiece)).up = false;
			
			PaperPiece($entity.get(PaperPiece)).offsetX = DisplayObjectContainer(super.screen.content).mouseX -  Display($entity.get(Display)).displayObject.x;
			PaperPiece($entity.get(PaperPiece)).offsetY = DisplayObjectContainer(super.screen.content).mouseY -  Display($entity.get(Display)).displayObject.y;
			
			DisplayObjectContainer(super.screen.content).setChildIndex(Display($entity.get(Display)).displayObject, DisplayObjectContainer(super.screen.content).numChildren - 1);
			
			// release picked old up piece if not already - fixes a bug
			if(_pickedUpPiece){
				if(_pickedUpPiece != $entity){
					Interaction(_pickedUpPiece.get(Interaction)).up.dispatch(_pickedUpPiece);
				}
			}
			
			// update _pickedUpPiece to the new picked up piece
			_pickedUpPiece = $entity;

		}
		
		private function pieceUp($entity:Entity):void{
			
			super.shellApi.triggerEvent("playPaperSound");
			
			/**
			 * When a piece is let go, stop moving it by setting "down" = false
			 * Then scan for neighboring compatible pieces within an area.
			 * If one is found, "join them" and snap this piece into place.
			 */
			var draggedPiece:PaperPiece = $entity.get(PaperPiece);
			draggedPiece.down = false;
			draggedPiece.up = true;
			
			var draggedClip:DisplayObject = Display($entity.get(Display)).displayObject;
			
			var potentialMatches:Vector.<Entity>;
			
			switch(draggedPiece.type){
				case 1:
					potentialMatches = nearbyMatches($entity, PaperPieces(piecesManager.get(PaperPieces)).bpPieces);
					break;
				case 2:
					potentialMatches = nearbyMatches($entity, PaperPieces(piecesManager.get(PaperPieces)).pdPieces);
					break;
				case 3:
					potentialMatches = nearbyMatches($entity, PaperPieces(piecesManager.get(PaperPieces)).psPieces);
					break;
			}
			
			if(potentialMatches.length > 0){
				// join pieces
				for each(var pieceEntity:Entity in potentialMatches){
					var matchPiece:PaperPiece = pieceEntity.get(PaperPiece);
					var matchClip:DisplayObject = Display(pieceEntity.get(Display)).displayObject;
					if(matchPiece.id < draggedPiece.id){ // matchPiece is left
						draggedClip.x = matchClip.x + (matchClip.width / 2) + (draggedClip.width / 2);
						draggedClip.y = matchClip.y;
						matchPiece.joinedRight = $entity;
						if (draggedPiece.joinedLeft == null) {
							super.shellApi.triggerEvent("playPieceCorrectSound");
						}
						draggedPiece.joinedLeft = pieceEntity;
					} else { // right
						draggedClip.x = matchClip.x - (matchClip.width / 2) - (draggedClip.width / 2);
						draggedClip.y = matchClip.y;
						matchPiece.joinedLeft = $entity;
						if (draggedPiece.joinedRight == null) {
							super.shellApi.triggerEvent("playPieceCorrectSound");
						}
						draggedPiece.joinedRight = pieceEntity;
					}
				}
			}
			
			// check if blue print is finished, if so, signal out that it is complete.
			var foundBP:Boolean = piecesComplete(PaperPieces(piecesManager.get(PaperPieces)).bpPieces);
			
			if(foundBP == true){
				finishedBluePrint();
			}
			
		}
		
		private function piecesComplete($pieces:Vector.<Entity>):Boolean{
			var complete:Boolean = true;
			
			for(var c:int = 0; c < $pieces.length - 1; c++){
				if(PaperPiece($pieces[c].get(PaperPiece)).joinedRight == null){
					complete = false;
				}
			}
			
			return complete;
		}
		
		private function nearbyMatches($paperPieceEntity:Entity, $pieces:Vector.<Entity>):Vector.<Entity>{
			
			/**
			 * Find nearby pieces in orientation to left or right of the piece and check if they have both the correct type or +/-1 id (left or right)
			 * If found, (up to 2 can be found) - return a vector of those possible entities.
			 */
			
			var sourceClip:DisplayObject = Display($paperPieceEntity.get(Display)).displayObject;
			var sourcePiece:PaperPiece = $paperPieceEntity.get(PaperPiece);
			
			var matches:Vector.<Entity> = new Vector.<Entity>;
			
			for each(var entity:Entity in $pieces){
				var clip:DisplayObject = Display(entity.get(Display)).displayObject;
				var piece:PaperPiece = entity.get(PaperPiece);
				
				if(Math.abs(sourceClip.x - clip.x) < 60){
					if(Math.abs(sourceClip.y - clip.y) < 100){
						// check if id's line up
						if(sourceClip.x < clip.x){ // check left
							if(sourcePiece.id == piece.id - 1){
								matches.push(entity);
							}
						} else if(sourcePiece.id == piece.id +1){ // check right
							matches.push(entity);
						}
					}
				}
			}
			return matches;
		}
		
		private function resetPieces($removeMouseInteractions:Boolean = false):void{
			for each(var bpPiece:Entity in PaperPieces(piecesManager.get(PaperPieces)).bpPieces){
				pieceUp(bpPiece);
				if($removeMouseInteractions == true){
					Display(bpPiece.get(Display)).displayObject.mouseEnabled = false;
					Display(bpPiece.get(Display)).displayObject.mouseChildren = false;
				}
			}
			for each(var pdPiece:Entity in PaperPieces(piecesManager.get(PaperPieces)).pdPieces){
				pieceUp(pdPiece);
				if($removeMouseInteractions == true){
					Display(pdPiece.get(Display)).displayObject.mouseEnabled = false;
					Display(pdPiece.get(Display)).displayObject.mouseChildren = false;
				}
			}
			for each(var psPiece:Entity in PaperPieces(piecesManager.get(PaperPieces)).psPieces){
				pieceUp(psPiece);
				if($removeMouseInteractions == true){
					Display(psPiece.get(Display)).displayObject.mouseEnabled = false;
					Display(psPiece.get(Display)).displayObject.mouseChildren = false;
				}
			}
		}
		
		private function finishedBluePrint():void{
			if (!completedPuzzle) {
				super.shellApi.triggerEvent("playPageCompleteSound");
				completedPuzzle = true;
				resetPieces(true);
			}
			// Signal that the blueprint has been found (completed)
			// NOTE: Scene should have this listener setup: popup.bpFound.addOnce(...)
			bpFound.dispatch();
		}
		
		public var bpFound:Signal = new Signal();
		public var piecesManager:Entity;
		private var _interactions:Vector.<Interaction> = new Vector.<Interaction>; // store interactions for garbage collection on close
		private var completedPuzzle:Boolean = false;
		private var _pickedUpPiece:Entity;
	}
}

