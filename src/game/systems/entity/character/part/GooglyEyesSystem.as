package game.systems.entity.character.part
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.entity.character.part.GooglyEyes;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.entity.character.part.GooglyEyesNode;
	import game.systems.GameSystem;
	
	public class GooglyEyesSystem extends GameSystem
	{
		public function GooglyEyesSystem()
		{
			super( GooglyEyesNode, updateNode );
			super.nodeAddedFunction = ESNodeAddedFunction;
		}
		
		private function ESNodeAddedFunction( node:GooglyEyesNode ):void
		{
			// assign assets
			node.googlyEyes.left = MovieClip(node.display.displayObject)["left"];
			node.googlyEyes.right = MovieClip(node.display.displayObject)["right"];
			node.googlyEyes.npc = node.entity.get(Parent).parent;
			
			// apply external component string values and convert to numbers if provided
			if (node.googlyEyes.speed != null)
			{
				node.googlyEyes.baseSpeed = Number(node.googlyEyes.speed);
			}
			if (node.googlyEyes.timeFactor != null)
			{
				node.googlyEyes.timeMultiplier = Number(node.googlyEyes.timeFactor);
			}
			if (node.googlyEyes.moveFactor != null)
			{
				node.googlyEyes.moveMultiplier = Number(node.googlyEyes.moveFactor);
			}
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_npcNodes = systemManager.getNodeList( NpcNode );
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( NpcNode );
		}
		
		private function updateNode( node:GooglyEyesNode, time:Number ):void
		{
			var eyes:GooglyEyes = node.googlyEyes;
			//trace("rick " + eyes.moveFactor);
			eyes.time += time;
			var speed:Number = 0;
			if (eyes.npc.has(Motion))
			{
				// get npc speed as absolute
				speed = Math.abs(eyes.npc.get(Motion).totalVelocity.x);
				// if faster than current speed
				if (speed > eyes.extraSpeed)
				{
					eyes.extraSpeed = speed;
				}
			}
			// decay extra speed
			eyes.extraSpeed *= 0.95;
			// set angle
			var angle:Number = (eyes.baseSpeed + eyes.extraSpeed * eyes.moveMultiplier) * Math.cos(eyes.time * eyes.timeMultiplier);
			eyes.left.rotation = angle;
			eyes.right.rotation = angle;
		}
		
		private var playerSpatial:Spatial;
		private var _npcNodes:NodeList;
	}
}