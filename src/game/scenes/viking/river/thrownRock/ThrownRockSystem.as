package game.scenes.viking.river.thrownRock
{
	import game.systems.GameSystem;
	
	public class ThrownRockSystem extends GameSystem
	{
		public function ThrownRockSystem()
		{
			super(ThrownRockNode, updateNode);
		}
		
		private function updateNode(node:ThrownRockNode, time:Number):void
		{
			if(node.rock.active)
			{
				node.rock.elapsedTime += time;
				if(node.rock.elapsedTime >= node.rock.throwTime)
				{
					node.rock.elapsedTime = 0;
					node.rock.active = false;
				}
				
				var height:Number = node.rock.maxHeight * Math.sin(Math.PI * (node.rock.elapsedTime / node.rock.throwTime));
				node.addition.y = -height;
				
				node.rock.shadow.x = node.spatial.x;
				node.rock.shadow.y = node.spatial.y;
				
				node.rock.shadow.width = node.display.displayObject.width - (height * 0.2);
				node.rock.shadow.scaleY = node.rock.shadow.scaleX;
			}
		}
	}
}