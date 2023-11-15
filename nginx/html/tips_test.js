if(top.location == location){
	document.write("<style type=\"text/css\">");
	document.write(".conf_env_tips{");
	document.write("	position: fixed;");
	document.write("	_position:absolute;");
	document.write("	filter:alpha(opacity=60);");
	document.write("	-moz-opacity:0.60;");
	document.write("	opacity:0.60;");
	document.write("	top: 200px;");
	document.write("	left: 2px;");
	document.write("	margin: 0px auto;");
	document.write("	width: 20px;");
	document.write("	height:120px;");
	document.write("	border:1px solid #CCC;");
	document.write("	display: inline;");
	document.write("	line-height: 20px;");
	document.write("	text-align: center;");
	document.write("	font-size: 18px;");
	document.write("	font-weight: bold;");
	document.write("	word-wrap: break-word;");
	document.write("	word-break: nomal;");
	document.write("	background-color: #dc8e00;");
	document.write("	color: #fff;");
	document.write("	overflow: hidden;");
	document.write("	z-index: 999999;");
	document.write("}	");
	document.write("</style>");
	document.write("<div class=\"conf_env_tips\">︗ 测试环境 ︘</div>");
}
