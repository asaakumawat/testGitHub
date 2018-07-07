using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Mvc.Html;
using System.Text;

namespace DS4UEMR.Web.Common
{
    public static class ActionLinkExtensions
    {
        public static MvcHtmlString ContentAuthorized(this HtmlHelper htmlHelper, AuthorizeParameters authParams, Func<object, object> htmlContent)
        {
            if (htmlHelper.ActionAuthorized(authParams))
            {
                string html = Convert.ToString(htmlContent.Invoke(null));
                return new MvcHtmlString(html);
            }
            else
            {
                return MvcHtmlString.Empty;
            }
        }
    }

    public static class ActionExtensions
    {
        //This is used to get controller name its actions and  user authorization
        internal static bool ActionAuthorized(this HtmlHelper htmlHelper, AuthorizeParameters authParams)
        {
            if (HttpContext.Current != null)
            {
                if (HttpContext.Current.Session != null)
                {
                    //check that super admin login 
                    if (HttpContext.Current.Session["AdminUserId"] != null)
                    {
                        return true;
                    }
                    CustomAuthorizeAttribute customAuthrozation = new CustomAuthorizeAttribute();
                    int practiceUserId = Convert.ToInt32(HttpContext.Current.Session["IDPracticeUser"]);
                    int practiceId = Convert.ToInt32(HttpContext.Current.Session["PracticeId"]);
                    bool IsAuthorizedUser = customAuthrozation.IsUserAuthorized(practiceUserId, practiceId, authParams.ModuleName, authParams.ActionType);
                    return IsAuthorizedUser;
                }
            }
            return false;
        }
    }
    public class AuthorizeParameters
    {
        public string ModuleName { get; set; }
        public string ActionType { get; set; }
    }

}