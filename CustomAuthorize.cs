using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using DS4UEMR.Domain.Concrete;
using DS4UEMR.Domain.Entities;

namespace Demo.Web.Common
{
    public class CustomAuthorizeAttribute : AuthorizeAttribute
    {
        public string ModuleName { get; set; }
        public string ActionType { get; set; }
        private string[] AllActions = new string[] { "write", "read", "delete" };
        public EFPracticeRepository objPracticeRepo = new EFPracticeRepository();
        public override void OnAuthorization(AuthorizationContext filterContext)
        {
            if (HttpContext.Current != null)
            {
                if (HttpContext.Current.Session != null)
                {
                    //check that super admin login 
                    if (HttpContext.Current.Session["AdminUserId"] != null)
                    {
                        return;
                    }
                    int practiceUserId = Convert.ToInt32(HttpContext.Current.Session["IDPracticeUser"]);
                    int practiceId = Convert.ToInt32(HttpContext.Current.Session["PracticeId"]);
                    bool isAuthorizedUser = IsUserAuthorized(practiceUserId,practiceId, ModuleName, ActionType);
                    if(isAuthorizedUser==false)
                    {
                        filterContext.Result = new RedirectResult("/Account/AccessDenied");
                    }
                }
                else
                {
                    filterContext.Result = new RedirectResult("/Account/Login");
                }
            }
            else
            {
                filterContext.Result = new RedirectResult("/Account/Login");
            }
        }

        public bool IsUserAuthorized(int practiceUserId,int practiceId,string ModuleName,string ActionType)
        {
            var userRolesList = objPracticeRepo.UserAuthorizetion(practiceUserId,practiceId, ModuleName);
            if (userRolesList != null && !string.IsNullOrEmpty(ActionType))
            {
                UserAuthorizetion userRole;
                ActionType = ActionType.ToLower();
                if (AllActions.Contains(ActionType))
                {
                    userRole = userRolesList.Where(a =>
                        ((ActionType == "write") && ((a.RoleIsWriteable == true && a.UserIsWriteable == null) || a.UserIsWriteable == true))
                        ||
                        ((ActionType == "read") && ((a.RoleIsReadable == true && a.UserIsReadable == null) || a.UserIsReadable == true))
                        ||
                        ((ActionType == "delete") && ((a.RoleIsDeleteable == true && a.UserIsDeleteable == null) || a.UserIsDeleteable == true))
                        ).FirstOrDefault();
                }
                else
                {
                    userRole = userRolesList.Where(a =>
                      (!string.IsNullOrEmpty(a.RoleAnonymous) ? a.RoleAnonymous : "").ToLower().Contains(ActionType)
                       ).FirstOrDefault();
                }
                if (userRole == null)
                {
                    return false;
                }
            }
            else
            {
                return false;
            }
            return true;
        }
        public bool IsAuthorizedModule(string ModuleName,string ActionType)
        {
            int practiceUserId = Convert.ToInt32(HttpContext.Current.Session["IDPracticeUser"]);
            int practiceId = Convert.ToInt32(HttpContext.Current.Session["PracticeId"]);
            bool isAuthorizedModule = IsUserAuthorized(practiceUserId, practiceId, ModuleName, ActionType);
            return isAuthorizedModule;
        }
    }

    

}
