package game.scenes.virusHunter.backRoom.systems
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	
	import game.scenes.virusHunter.backRoom.components.PaperPiece;
	import game.scenes.virusHunter.backRoom.nodes.PaperPiecesNode;
	
	public class PaperPiecesSystem extends ListIteratingSystem
	{
		public function PaperPiecesSystem($container:DisplayObjectContainer)
		{
			_container = $container;
			super(PaperPiecesNode, updateNode);
		}
		
		private function updateNode($node:PaperPiecesNode, $time:Number):void{
			/**
			 * Check through all the pieces to see if the paperPiece.down == true
			 * if so, have it follow mouseX and mouseY
			 * linkPieces will have any snapped pieces follow as if it were linked
			 * 
			 * TODO: Confirm that mouseX and mouseY is sufficient for mobile
			 */
			for each(var bpPiece:Entity in $node.paperPieces.bpPieces){
				if(PaperPiece(bpPiece.get(PaperPiece)).down == true){
					Display(bpPiece.get(Display)).displayObject.x = _container.mouseX - PaperPiece(bpPiece.get(PaperPiece)).offsetX;
					Display(bpPiece.get(Display)).displayObject.y = _container.mouseY - PaperPiece(bpPiece.get(PaperPiece)).offsetY;
					
					linkPieces(bpPiece, $node.paperPieces.bpPieces);
				}
			}
			for each(var pdPiece:Entity in $node.paperPieces.pdPieces){
				if(PaperPiece(pdPiece.get(PaperPiece)).down == true){
					Display(pdPiece.get(Display)).displayObject.x = _container.mouseX - PaperPiece(pdPiece.get(PaperPiece)).offsetX;
					Display(pdPiece.get(Display)).displayObject.y = _container.mouseY - PaperPiece(pdPiece.get(PaperPiece)).offsetY;
					
					linkPieces(pdPiece, $node.paperPieces.pdPieces);
				}
			}
			for each(var psPiece:Entity in $node.paperPieces.psPieces){
				if(PaperPiece(psPiece.get(PaperPiece)).down == true){
					Display(psPiece.get(Display)).displayObject.x = _container.mouseX - PaperPiece(psPiece.get(PaperPiece)).offsetX;
					Display(psPiece.get(Display)).displayObject.y = _container.mouseY - PaperPiece(psPiece.get(PaperPiece)).offsetY;
					
					linkPieces(psPiece, $node.paperPieces.psPieces);
				}
			}
		}
		
		private function linkPieces($origPieceEntity:Entity, $pieceEntities:Vector.<Entity>):void{
			
			/**
			 * from the original piece, start checking the left pieces step by step, if a piece is there link it to the correct coordinates
			 * Do the same from the original piece for the right.
			 */
			
			var origPiece:PaperPiece = $origPieceEntity.get(PaperPiece);
			var origClip:DisplayObject = Display($origPieceEntity.get(Display)).displayObject;
			
			var targEntity:Entity;
			var targPiece:PaperPiece;
			var targClip:DisplayObject;
			
			var joinedClip:DisplayObject;
			
			// check left
			targEntity = $origPieceEntity;
			
			while(targEntity != null){
				targPiece = targEntity.get(PaperPiece);
				targClip = Display(targEntity.get(Display)).displayObject;
				
				if(targPiece.joinedLeft){
					var leftClip:DisplayObject = Display(targPiece.joinedLeft.get(Display)).displayObject;
					
					leftClip.x = targClip.x - (targClip.width/2) - (leftClip.width/2);
					leftClip.y = targClip.y;
					
					_container.setChildIndex(leftClip, _container.numChildren - 1);
				}
				
				targEntity = targPiece.joinedLeft;
			}
			
			// check right
			targEntity = $origPieceEntity;
			
			while(targEntity != null){
				targPiece = targEntity.get(PaperPiece);
				targClip = Display(targEntity.get(Display)).displayObject;
				
				if(targPiece.joinedRight){
					var rightClip:DisplayObject = Display(targPiece.joinedRight.get(Display)).displayObject;
					
					rightClip.x = targClip.x + (targClip.width/2) + (rightClip.width/2);
					rightClip.y = targClip.y;
					
					_container.setChildIndex(rightClip, _container.numChildren - 1);
				}
				
				targEntity = targPiece.joinedRight;
			}
		}
		
		private var _container:DisplayObjectContainer;
	}
}