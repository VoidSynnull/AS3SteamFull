package game.scenes.start.login.components
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Component;
	
	import game.util.ColorUtil;
	import game.util.TextUtils;
	
	public class ContextButton extends Component
	{
		public function get TF():TextField{return tf;}
		private var tf:TextField;
		private var fill:MovieClip;
		private var text:String;
		private var next:MovieClip;
		private var back:MovieClip;
		private var color:Number = 0xffffff;
		public var context:String;
		
		public function ContextButton(clip:MovieClip, font:String = "CreativeBlock BB")
		{
			tf = clip.text;
			tf = TextUtils.refreshText(tf, font);
			tf.autoSize = TextFieldAutoSize.CENTER;
			fill = clip.bg;
			next = clip.next;
			back = clip.back;
			text = tf.text;
		}
		
		public function Update(text:String = null, color:Number = -1, context:String = null):void
		{
			if(text != null)
			{
				this.text = text;
				if(context == null)
					context = text;
			}
				
			if(color >= 0)
				this.color = color;
			
			if(context != null)
				this.context = context;
			
			next.visible = text.toLowerCase() == "next";
			back.visible = text.toLowerCase() == "back";
			
			tf.text = this.text;
			ColorUtil.colorize(fill, this.color);
			trace("tf size: " + tf.getRect(tf.parent) + " : (" + tf.width + "," + tf.height+")");
			tf.x = -tf.width/2;
			tf.y = -tf.textHeight/2;
		}
	}
}