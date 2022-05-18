package game.systems.ui
{
	import game.nodes.ui.BookNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class BookSystem extends GameSystem
	{
		public function BookSystem()
		{
			super(BookNode, updateNode, nodeAdded);
			
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:BookNode, time:Number):void
		{
			if(!node.book.invalidate) return;
			
			if(node.book.ease)
			{
				var deltaX:Number = node.book.offsetX - node.addition.x;
				var deltaY:Number = node.book.offsetY - node.addition.y;
				
				/**
				 * Hardcoded 0.1 threshold. This could be a Book variable, but 0.1 seems to work for anything
				 * with a decent easing rate.
				 */
				if(Math.abs(deltaX) < node.book.minDelta && Math.abs(deltaY) < node.book.minDelta)
				{
					this.pageTurnComplete(node);
					return;
				}
				
				node.addition.x += deltaX * node.book.rate * time;
				node.addition.y += deltaY * node.book.rate * time;
			}
			else
			{
				this.pageTurnComplete(node);
			}
		}
		
		private function pageTurnComplete(node:BookNode):void
		{
			node.book.invalidate = false;
			node.addition.x = node.book.offsetX;
			node.addition.y = node.book.offsetY;
			node.book.pageTurnFinished.dispatch(node.book);
		}
		
		private function nodeAdded(node:BookNode):void
		{
			/**
			 * The Book will be initially turned to whatever page number you specify in the Book's constructor.
			 */
			this.pageTurnComplete(node);
		}
	}
}