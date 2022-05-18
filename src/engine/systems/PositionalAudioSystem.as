package engine.systems 
{	
	import com.greensock.easing.Linear;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	import engine.nodes.PositionalAudioNode;
	
	public class PositionalAudioSystem extends ListIteratingSystem 
	{
		public function PositionalAudioSystem()
		{
			super(PositionalAudioNode, updateNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(PositionalAudioNode);
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:PositionalAudioNode, time:Number):void
		{			
			var cameraX:Number;
			var cameraY:Number;
			
			if(_shellApi.camera != null)
			{
				cameraX = -_shellApi.camera.x;
				cameraY = -_shellApi.camera.y;
			}
			else
			{
				// default to a centered camera if the 'real' camera doesn't exist.
				cameraX = _shellApi.viewportWidth * .5;
				cameraY = _shellApi.viewportHeight * .5;
			}
			
			var node_x:Number = node.spatial.x;
			var node_y:Number = node.spatial.y;
			
			var distance:Number = Math.sqrt(Math.pow(cameraX - node_x, 2) + Math.pow(cameraY - node_y, 2));
			
			var volume:Number;
			var pan:Number;
			
			if(distance >= node.range.radius){
				volume = node.range.minVolume;
			}else if(distance == 0){
				volume = node.range.maxVolume
			}else{
				var tween:Function = ((node.range.tween != null) ? node.range.tween : Linear.easeInOut);
				var percent:Number = 1-(distance/node.range.radius);
				volume = tween(percent * node.range.radius, node.range.minVolume, node.range.maxVolume - node.range.minVolume, node.range.radius);
			}
			pan =  Math.min(1, Math.max(-1, (node_x - cameraX)/(_shellApi.viewportWidth * .5)));
			node.audio.setPosition(volume, pan);
		}
		
		[Inject]
		public var _shellApi:ShellApi
	}
}