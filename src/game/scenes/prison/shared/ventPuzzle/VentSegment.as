package game.scenes.prison.shared.ventPuzzle
{
	import ash.core.Component;
	
	public class VentSegment extends Component
	{
		public var parentId:String;
		public var left:String;
		public var up:String;
		public var right:String;
		public var down:String;
		
		public var rotation:int = 0;
		
		public function VentSegment(rotation:Number, left:String, up:String, right:String, down:String, parentId:String)
		{
			this.rotation = rotation;
			this.left = left;
			this.up = up;
			this.right = right;
			this.down = down;
			this.parentId = parentId;
		}
		
		public function updateRotation(newRotation:int):void
		{
			rotation = newRotation;
		}
		
		public function getNextVentId(inputId:String):String
		{
			var next:String = "";
			if(inputId == left){
				if(rotation == 0){
					next = down;
				}
				else if(rotation == 90){
					next = up;
				}
				else{
					//0 default
					next = down;
				}
			}
			else if(inputId == up){
				if(rotation == 0){
					next = right;
				}
				else if(rotation == 90){
					next = left;
				}
				else{
					next = right;
				}
			}			
			else if(inputId == right){
				if(rotation == 0){
					next = up;
				}
				else if(rotation == 90){
					next = down;
				}
				else{
					next = up;
				}
			}			
			else if(inputId == down){
				if(rotation == 0){
					next = left;
				}
				else if(rotation == 90){
					next = right;
				}
				else{
					next = left;
				}
			}
			trace("NEXT VENT FOUND:"+next);
			return next;
		}
		
	}
}