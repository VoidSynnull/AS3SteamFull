package game.systems.video
{
	import ash.core.Engine;
	import game.nodes.video.PopVideoNode;
	import game.systems.GameSystem;
	
	public class PopVideoSystem extends GameSystem
	{
		// currently playing video node
		private var _playing:PopVideoNode;
		
		public function PopVideoSystem()
		{
			super(PopVideoNode, updateNode, null, nodeRemoved);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(PopVideoNode);		
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:PopVideoNode, time:Number):void
		{
			// get video status
			var vStatus:String = node.popVideo.pStatus;
			switch(vStatus)
			{
				case "start":
					// request to start video
					node.popVideo.fnPlay();
					// remember node
					_playing = node;
					break;
				case "playing":
					// check to see if any VAST events must be triggered
					//node.popVideo.checkProgressForVAST();
					// if playing and not currently playing video node, then stop other videos
					if (_playing != node)
						node.popVideo.fnStop();
					break;
				case "replay":
					// request to replay video
					node.popVideo.fnReplay();
					// remember node
					_playing = node;
					break;
			}
		}
		
		private function nodeRemoved(node:PopVideoNode):void
		{
			node.popVideo.fnDispose();
		}
	}
}