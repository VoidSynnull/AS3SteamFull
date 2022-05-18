package game.scenes.deepDive2.pipeRoom.systems
{	
	import ash.core.Entity;
	
	import game.scenes.deepDive2.pipeRoom.components.Pipe;
	import game.scenes.deepDive2.pipeRoom.nodes.PipeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class PipeSystem extends GameSystem
	{
		public var currentPath:Array;
		
		public function PipeSystem()
		{
			this._defaultPriority = SystemPriorities.update;
			currentPath = new Array();
			super(PipeNode,updateNode,addNode);
		}
		
		private function addNode(node:PipeNode):void
		{
			//trace("Pipe ADD: "+node.id.id)
		}
		
		override public function update(time:Number):void
		{
			
			super.update(time);
		}
		
		private function updateNode(node:PipeNode,time:Number):void
		{
			//trace("Pipe UPDATE: "+node.id.id)
			var pipeEnt:Entity = node.entity;
			var pipe:Pipe = node.pipe;
			// update link status of pipe
			updateRotation(node,pipe);
			if(pipe.rotationUpdated){
				updatePath(nodeList.head);
				pipe.rotationUpdated = false;
			}
			
		}
		
		
		private function updateRotation(node:PipeNode, pipe:Pipe):void
		{
			switch(pipe.type)
			{
				case Pipe.TYPE_BAR:
					if(pipe.rotation == 0 || pipe.rotation == 2){
						pipe.up = false;
						pipe.right = true;
						pipe.down = false;
						pipe.left = true;
					}
					else if(pipe.rotation == 1 || pipe.rotation == 3){
						pipe.up = true;
						pipe.right = false;
						pipe.down = true;
						pipe.left = false;
					}
					break;
				case Pipe.TYPE_ANGLE:
					if(pipe.rotation == 0){
						pipe.up = false;
						pipe.right = true;
						pipe.down = true;
						pipe.left = false;
					}
					else if(pipe.rotation == 1){
						pipe.up = false;
						pipe.right = false;
						pipe.down = true;
						pipe.left = true;
					}
					else if(pipe.rotation == 2){
						pipe.up = true;
						pipe.right = false;
						pipe.down = false;
						pipe.left = true;
					}
					else if(pipe.rotation == 3){
						pipe.up = true;
						pipe.right = true;
						pipe.down = false;
						pipe.left = false;
					}
					break;
				case Pipe.TYPE_START:
					pipe.up = false;
					pipe.right = false;
					pipe.down = false;
					pipe.left = true;
					break;
				case Pipe.TYPE_END:
					pipe.up = false;
					pipe.right = true;
					pipe.down = false;
					pipe.left = false;
					break;
			};
		}
		
		public function updatePath(startingNode:PipeNode = null):void
		{
			currentPath = new Array();
			//var curr:PipeNode = node;
			var curr:Entity;
			if(startingNode){
				curr= startingNode.entity;
			}else{
				curr = nodeList.head.entity;
			}
			// add starting pipe
			currentPath.push(curr);
			var prev:Entity = null;
			var next:Entity = null;
			var pipe:Pipe;
			var otherPipe:Pipe;
			while(curr){
			    pipe = curr.get(Pipe);
				otherPipe = null;
				if(pipe.type == Pipe.TYPE_BAR){
					next = nextBar(pipe,curr,prev);
				}
				else if(pipe.type == Pipe.TYPE_ANGLE){
					next = nextBar(pipe,curr,prev);
				}
				else if(pipe.type == Pipe.TYPE_START){
					next = nextFromStart(pipe,curr,prev);
				}
				else if(pipe.type == Pipe.TYPE_END){
					pipe.endPiece = true;
					next = null;
				}
				
				if(next){
					if(currentPath.indexOf(next) < 0){
						currentPath.push(next);
					}
				}
				prev = curr;
				curr = next;
			}
		}
		
		private function nextFromStart(pipe:Pipe, curr:Entity, prev:Entity):Entity
		{
			var next:Entity = null;
			var otherPipe:Pipe;
			if(pipe.left && pipe.leftNeighbor && (!prev || prev!=pipe.leftNeighbor)){
				otherPipe = pipe.leftNeighbor.get(Pipe);
				if(otherPipe.right && otherPipe.rightNeighbor == curr){
					// valid link
					next = pipe.leftNeighbor;
				}
			}					
			pipe.exitDirection = 3;

			return next;
		}
		
		private function nextBar(pipe:Pipe, curr:Entity, prev:Entity):Entity
		{
			var next:Entity = null;
			var otherPipe:Pipe;
			if(pipe.up && pipe.upNeighbor && (!prev || prev!=pipe.upNeighbor)){
				otherPipe = pipe.upNeighbor.get(Pipe);
				if(otherPipe.down && otherPipe.downNeighbor == curr){
					// valid link
					next = pipe.upNeighbor;
				}
			}
			else if(pipe.right && pipe.rightNeighbor && (!prev || prev!=pipe.rightNeighbor)){
				otherPipe = pipe.rightNeighbor.get(Pipe);
				if(otherPipe.left && otherPipe.leftNeighbor == curr){
					// valid link
					next = pipe.rightNeighbor;
				}
			}
			else if(pipe.down && pipe.downNeighbor && (!prev || prev!=pipe.downNeighbor)){
				otherPipe = pipe.downNeighbor.get(Pipe);
				if(otherPipe.up && otherPipe.upNeighbor == curr){
					// valid link
					next = pipe.downNeighbor;
				}
			}
			else if(pipe.left && pipe.leftNeighbor && (!prev || prev!=pipe.leftNeighbor)){
				otherPipe = pipe.leftNeighbor.get(Pipe);
				if(otherPipe.right && otherPipe.rightNeighbor == curr){
					// valid link
					next = pipe.leftNeighbor;
				}
			}
			pipe.exitDirection = findExitDir(pipe, curr, prev);
			return next;
		}
				
		private function findExitDir(pipe:Pipe, curr:Entity, prev:Entity):int
		{
			var result:int = 3;
			var otherPipe:Pipe;
			if(prev){
				if(pipe.upNeighbor){
					otherPipe = pipe.upNeighbor.get(Pipe);
					if(pipe.up && otherPipe.down){
						if(pipe.right){
							result = 1;
						}else if(pipe.down){
							result = 2;
						}else if(pipe.left){
							result = 3;
						}
					}
				}
				if(pipe.rightNeighbor){
					otherPipe = pipe.rightNeighbor.get(Pipe);
					if(pipe.right && otherPipe.left){
						if(pipe.down){
							result = 2;
						}else if(pipe.left){
							result = 3;
						}else if(pipe.up){
							result = 0;
						}
					}
				}
				if(pipe.downNeighbor){
					otherPipe = pipe.downNeighbor.get(Pipe);
					if(pipe.down && otherPipe.up){
						if(pipe.left){
							result = 3;
						}else if(pipe.up){
							result = 0;
						}else if(pipe.right){
							result = 1;
						}
					}
				}
				if(pipe.leftNeighbor){
					otherPipe = pipe.leftNeighbor.get(Pipe);
					if(pipe.left && otherPipe.right){
						if(pipe.up){
							result = 0;
						}else if(pipe.right){
							result = 1;
						}else if(pipe.down){
							result = 2;
						}
					}
				}
			}
			
			return result;
		}
		
		
		
		
		
		
		
		
		
		
		
		
	};
};