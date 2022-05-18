package game.adparts.systems
{
	import ash.core.Engine;
	
	import game.adparts.nodes.AdVideoNode;
	import game.systems.GameSystem;
	
	public class AdVideoSystem extends GameSystem
	{
		// currently playing video node
		private var _playing:AdVideoNode;
		
		public function AdVideoSystem()
		{
			super(AdVideoNode, updateNode, null, nodeRemoved);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(AdVideoNode);		
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:AdVideoNode, time:Number):void
		{
			// get video status
			var vStatus:String = node.adVideo.pStatus;
			switch(vStatus)
			{
				case "start":
					// request to start video
					node.adVideo.fnPlay();
					// remember node
					_playing = node;
					break;
				case "playing":
					if (_playing == node)
					{
						node.adVideo.updateProgress();
						// check to see if any VAST events must be triggered
						node.adVideo.checkProgressForVAST();
					}
					else
					{
						// if playing and not currently playing video node, then stop other videos
						node.adVideo.fnStop();
					}
					break;
				case "replay":
					// request to replay video
					node.adVideo.fnReplay();
					// remember node
					_playing = node;
					break;
			}
		}
		
		private function nodeRemoved(node:AdVideoNode):void
		{
			node.adVideo.fnDispose();
		}
		
		public function stopCurrent():void
		{
			_playing = null;
		}
	}
}